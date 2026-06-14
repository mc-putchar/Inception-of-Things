#!/bin/bash

# Script to apply or delete app3 Kubernetes resources

# Check command-line argument
if [ "$1" = "apply" ]; then
  echo "[INFO] Applying app3 resources..."
  echo "[INFO] Applying app3 ConfigMap..."
  kubectl apply -f /vagrant/k8s/app3-configmap.yaml
  echo "[INFO] Applying app3 Deployment..."
  kubectl apply -f /vagrant/k8s/app3-deployment.yaml
  echo "[INFO] Applying app3 Service..."
  kubectl apply -f /vagrant/k8s/app3-service.yaml
  echo "[INFO] app3 resources applied."
elif [ "$1" = "delete" ]; then
  echo "[INFO] Deleting app3 resources..."
  echo "[INFO] Deleting app3 Service..."
  kubectl delete -f /vagrant/k8s/app3-service.yaml
  echo "[INFO] Deleting app3 Deployment..."
  kubectl delete -f /vagrant/k8s/app3-deployment.yaml
  echo "[INFO] Deleting app3 ConfigMap..."
  kubectl delete -f /vagrant/k8s/app3-configmap.yaml
  echo "[INFO] app3 resources deleted."
else
  echo "[ERROR] Invalid argument. Usage: $0 {apply|delete}"
  exit 1
fi

