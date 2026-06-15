#!/usr/bin/env bash

set -e

REPOSITORY_NAME=${1:-"mcutura-42playground"}

echo "Waiting for gitlab-toolbox to be ready..."
kubectl rollout status deployment/gitlab-toolbox -n gitlab --timeout=2m

echo "Creating '${REPOSITORY_NAME}' repository under the root account..."
kubectl exec -i -n gitlab deployment/gitlab-toolbox \
  -- env REPO_NAME="${REPOSITORY_NAME}" gitlab-rails runner '
user = User.find_by(username: "root")
project = Project.find_by(path: ENV["REPO_NAME"], namespace: user.namespace)

if project.nil?
  project = Projects::CreateService.new(user,
    name: ENV["REPO_NAME"],
    path: ENV["REPO_NAME"],
    namespace_id: user.namespace.id,
    visibility_level: Gitlab::VisibilityLevel::PUBLIC
  ).execute

  if project.persisted?
    puts "✅ Repository successfully created and initialized!"
  else
    puts "❌ Failed to create project: #{project.errors.full_messages.join(", ")}"
    exit 1
  end
else
  puts "ℹ️ Repository already exists."
end
'

echo "---------------------------------------------------------"
echo "Push the repo:"
echo "  git remote add gitlab http://gitlab.127.0.0.1.nip.io:8081/root/${REPOSITORY_NAME}.git"
echo "  git push -u gitlab main"
echo "ArgoCD repoURL:"
echo "  http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/${REPOSITORY_NAME}.git"
echo "---------------------------------------------------------"
