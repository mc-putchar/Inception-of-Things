#!/usr/bin/env bash

set -e

source ~/mnt/bonus/confs/credentials.env

echo "Cleaning up previous deployments..."
k3d cluster delete gitlab || true

k3d cluster create gitlab --agents 2 \
    --port '80:80@loadbalancer' \
    --port '443:443@loadbalancer' \
    --port '8081:80@loadbalancer' \
    --port '8080:30080@server:0' \
    --port '8888:30888@server:0'

kubectl apply -f ~/mnt/bonus/confs/namespaces.yaml

# Install ArgoCD
kubectl apply -n argocd \
    --server-side \
    --force-conflicts \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# Patch Argo CD Server service to use NodePort 30080
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "nodePort": 30080}]}}'

# Add Helm repositories
helm repo add gitlab https://charts.gitlab.io/
helm repo add valkey https://valkey.io/valkey-helm/
helm plugin install --verify=false https://github.com/aslafy-z/helm-git || true
helm repo add garage "git+https://git.deuxfleurs.fr/Deuxfleurs/garage.git@script/helm?ref=v2.2.0"
helm repo update

kubectl create secret generic gitlab-root-password -n gitlab \
  --from-literal=password="${GITLAB_ROOT_PASS}"

helm install valkey valkey/valkey -n gitlab \
  -f ~/mnt/bonus/confs/valkey-values.yaml \
  --set auth.aclUsers.default.password="${REDIS_PASS}"

# Deploy CloudNativePG Operator & Cluster Configuration
kubectl apply \
  --server-side \
  -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.28/releases/cnpg-1.28.0.yaml
kubectl rollout status deployment/cnpg-controller-manager -n cnpg-system --timeout=2m

kubectl apply -f ~/mnt/bonus/confs/cnpg-cluster.yaml

# Deploy Garage Object Storage
helm install garage garage/garage -n gitlab \
  -f ~/mnt/bonus/confs/garage-values.yaml

echo "Waiting for Garage system layout to settle..."
kubectl rollout status statefulset/garage -n gitlab --timeout=3m

GARAGE_POD="garage-0"

# Dynamically gather runtime node IDs from status to assign layout zones
echo "Configuring Garage internal layout zones..."
set +e
NODE_IDS=""
NUM_NODES=0

# Explicitly loop until all 3 instances have joined the internal cluster matrix
while [ "$NUM_NODES" -lt 3 ]; do
  echo "Fetching Garage Node IDs..."
  RAW_STATUS=$(kubectl exec -n gitlab $GARAGE_POD -- /garage status 2>/dev/null)

  # Extract node IDs
  NODE_IDS=$(echo "$RAW_STATUS" | grep -E '^[0-9a-f]{16}\s' | awk '{print $1}')

  # Safely count whitespace/newline-separated words (IDs)
  NUM_NODES=$(echo "$NODE_IDS" | wc -w)

  if [ "$NUM_NODES" -lt 3 ]; then
    echo "Garage mesh only sees $NUM_NODES/3 healthy nodes. Waiting for peer discovery..."
    sleep 5
  fi
done
set -e

# Cleanly iterate through all 3 verified node IDs
ZONE_NUM=1
for NODE_ID in $NODE_IDS; do
  echo "Assigning layout role to node: ${NODE_ID} in zone gitlab${ZONE_NUM}..."
  kubectl exec -n gitlab $GARAGE_POD -- /garage layout assign -z "gitlab${ZONE_NUM}" -c 5G "$NODE_ID"
  ZONE_NUM=$((ZONE_NUM + 1))
done

echo "Applying storage system layout..."
kubectl exec -n gitlab $GARAGE_POD -- /garage layout apply --version 1

echo "Creating object buckets..."
buckets=("git-lfs" "gitlab-agent-plan-content" "gitlab-artifacts" "gitlab-backups" \
         "gitlab-ci-secure-files" "gitlab-dependency-proxy" "gitlab-mr-diffs" \
         "gitlab-packages" "gitlab-pages" "gitlab-terraform-state" "gitlab-uploads" \
         "registry" "runner-cache" "tmp" )
for bucket in "${buckets[@]}"; do
  kubectl exec -n gitlab $GARAGE_POD -- /garage bucket create "${bucket}"
done

# Provision internal API access keys and retrieve secret text maps
echo "Generating bucket credentials..."
KEY_OUTPUT=$(kubectl exec -n gitlab $GARAGE_POD -- /garage key create gitlab-app-key)
GARAGE_ACCESS_KEY=$(echo "${KEY_OUTPUT}" | grep 'Key ID:' | awk '{print $3}')
GARAGE_SECRET_KEY=$(echo "${KEY_OUTPUT}" | grep 'Secret key:' | awk '{print $3}')

for bucket in "${buckets[@]}"; do
  kubectl exec -n gitlab $GARAGE_POD -- /garage bucket allow --read --write --key gitlab-app-key "${bucket}"
done

echo "Inverting credentials to expected GitLab YAML-Secret formatting..."
cat <<EOF | kubectl create secret generic gitlab-object-storage -n gitlab --from-file=config=/dev/stdin
provider: AWS
region: garage
aws_access_key_id: ${GARAGE_ACCESS_KEY}
aws_secret_access_key: ${GARAGE_SECRET_KEY}
endpoint: "http://garage.gitlab.svc.cluster.local:3900"
path_style: true
EOF

cat <<EOF | kubectl create secret generic gitlab-object-storage-s3cmd -n gitlab --from-file=config=/dev/stdin
[default]
access_key = ${GARAGE_ACCESS_KEY}
secret_key = ${GARAGE_SECRET_KEY}
host_base = garage.gitlab.svc.cluster.local:3900
host_bucket = garage.gitlab.svc.cluster.local:3900
use_https = False
EOF

cat <<EOF | kubectl create secret generic gitlab-registry-storage -n gitlab --from-file=config=/dev/stdin
s3:
  accesskey: ${GARAGE_ACCESS_KEY}
  secretkey: ${GARAGE_SECRET_KEY}
  bucket: registry
  region: garage
  regionendpoint: http://garage.gitlab.svc.cluster.local:3900
  secure: false
  v4auth: true
  pathstyle: true
EOF

echo "Verifying PostgreSQL Cluster readiness..."
until [ "$(kubectl get cluster gitlab-rails-db -n gitlab -o jsonpath='{.status.readyInstances}' 2>/dev/null)" == "1" ]; do
  sleep 5
done

echo "Booting infrastructure chart..."
helm install gitlab gitlab/gitlab \
  -n gitlab \
  -f ~/mnt/bonus/confs/gitlab-values.yaml \
  --skip-crds \
  --timeout 900s

echo "Waiting for GitLab Webservice to become ready..."
kubectl rollout status deployment/gitlab-webservice-default -n gitlab --timeout=25m

kubectl apply -f ~/mnt/bonus/confs/argocd-app.yaml

echo "================================================="
echo "GitLab Web URL: http://gitlab.127.0.0.1.nip.io:8081"
echo "ArgoCD UI URL: http://localhost:8080"
echo "Playground app: http://localhost:8888"
echo "================================================="
echo "GitLab Credentials:"
echo "Username: root"
echo -n "Password: "
kubectl get secret gitlab-root-password -n gitlab -o jsonpath="{.data.password}" | base64 -d; echo;
echo "================================================="
echo "ArgoCD Credentials:"
echo "Username: admin"
echo -n "Password: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo;
echo "================================================="
