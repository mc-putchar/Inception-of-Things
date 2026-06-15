#!/usr/bin/env bash

set -e

k3d cluster delete iot-cluster || true

k3d cluster create iot-cluster \
  --api-port 6550 \
  --agents 1 \
  -p "8888:30888@server:0" \
  -p "8080:30080@server:0"

kubectl apply -f ~/mnt/p3/confs/namespaces.yaml

kubectl apply -n argocd \
  --server-side \
  --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd \
    -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "nodePort": 30080}]}}'

kubectl apply -f ~/mnt/p3/confs/argocd-app.yaml

echo "Waiting for ArgoCD API to generate initial secrets..."
sleep 10

echo "================================================="
echo "Access ArgoCD at: https://localhost:8080"
echo "Access the Playground App at: http://localhost:8888"
echo "================================================="
echo "ArgoCD Login Credentials:"
echo "Username: admin"
echo -n "Password: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo;
echo "================================================="
