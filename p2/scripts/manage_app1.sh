#!/bin/bash

# Script to apply or delete app1 Kubernetes resources

# Check command-line argument
if [ "$1" = "apply" ]; then
  echo "[INFO] Applying app1 resources..."
  echo "[INFO] Applying app1 Deployment..."
  kubectl apply -f /vagrant/k8s/app1-deployment.yaml
  echo "[INFO] Applying app1 Service..."
  kubectl apply -f /vagrant/k8s/app1-service.yaml
  echo "[INFO] app1 resources applied."
elif [ "$1" = "delete" ]; then
  echo "[INFO] Deleting app1 resources..."
  echo "[INFO] Deleting app1 Service..."
  kubectl delete -f /vagrant/k8s/app1-service.yaml
  echo "[INFO] Deleting app1 Deployment..."
  kubectl delete -f /vagrant/k8s/app1-deployment.yaml
  echo "[INFO] app1 resources deleted."
else
  echo "[ERROR] Invalid argument. Usage: $0 {apply|delete}"
  exit 1
fi

