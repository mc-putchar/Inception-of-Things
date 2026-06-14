#!/bin/bash

# Script to apply or delete app2 Kubernetes resources

# Check command-line argument
if [ "$1" = "apply" ]; then
  echo "[INFO] Applying app2 resources..."
  echo "[INFO] Applying app2 ConfigMap..."
  kubectl apply -f /vagrant/k8s/app2-configmap.yaml
  echo "[INFO] Applying app2 Deployment..."
  kubectl apply -f /vagrant/k8s/app2-deployment.yaml
  echo "[INFO] Applying app2 Service..."
  kubectl apply -f /vagrant/k8s/app2-service.yaml
  echo "[INFO] app2 resources applied."
elif [ "$1" = "delete" ]; then
  echo "[INFO] Deleting app2 resources..."
  echo "[INFO] Deleting app2 Service..."
  kubectl delete -f /vagrant/k8s/app2-service.yaml
  echo "[INFO] Deleting app2 Deployment..."
  kubectl delete -f /vagrant/k8s/app2-deployment.yaml
  echo "[INFO] Deleting app2 ConfigMap..."
  kubectl delete -f /vagrant/k8s/app2-configmap.yaml
  echo "[INFO] app2 resources deleted."
else
  echo "[ERROR] Invalid argument. Usage: $0 {apply|delete}"
  exit 1
fi

