#!/bin/bash

# script to apply or delete app1, app2, app3, and Ingress resources

if [ "$1" = "apply" ]; then
  echo "[INFO] Applying resources..."
  echo "[INFO] Applying app1 Deployment..."
  kubectl apply -f /vagrant/k8s/app1-deployment.yaml
  echo "[INFO] Applying app1 Service..."
  kubectl apply -f /vagrant/k8s/app1-service.yaml
  echo "[INFO] Applying app2 ConfigMap..."
  kubectl apply -f /vagrant/k8s/app2-configmap.yaml
  echo "[INFO] Applying app2 Deployment..."
  kubectl apply -f /vagrant/k8s/app2-deployment.yaml
  echo "[INFO] Applying app2 Service..."
  kubectl apply -f /vagrant/k8s/app2-service.yaml
  echo "[INFO] Applying app3 ConfigMap..."
  kubectl apply -f /vagrant/k8s/app3-configmap.yaml
  echo "[INFO] Applying app3 Deployment..."
  kubectl apply -f /vagrant/k8s/app3-deployment.yaml
  echo "[INFO] Applying app3 Service..."
  kubectl apply -f /vagrant/k8s/app3-service.yaml
  echo "[INFO] Applying Ingress..."
  kubectl apply -f /vagrant/k8s/apps-ingress.yaml
  echo "[INFO] Resources applied."
elif [ "$1" = "delete" ]; then
  echo "[INFO] Deleting resources..."
  echo "[INFO] Deleting Ingress..."
  kubectl delete -f /vagrant/k8s/apps-ingress.yaml
  echo "[INFO] Deleting app3 Service..."
  kubectl delete -f /vagrant/k8s/app3-service.yaml
  echo "[INFO] Deleting app3 Deployment..."
  kubectl delete -f /vagrant/k8s/app3-deployment.yaml
  echo "[INFO] Deleting app3 ConfigMap..."
  kubectl delete -f /vagrant/k8s/app3-configmap.yaml
  echo "[INFO] Deleting app2 Service..."
  kubectl delete -f /vagrant/k8s/app2-service.yaml
  echo "[INFO] Deleting app2 Deployment..."
  kubectl delete -f /vagrant/k8s/app2-deployment.yaml
  echo "[INFO] Deleting app2 ConfigMap..."
  kubectl delete -f /vagrant/k8s/app2-configmap.yaml
  echo "[INFO] Deleting app1 Service..."
  kubectl delete -f /vagrant/k8s/app1-service.yaml
  echo "[INFO] Deleting app1 Deployment..."
  kubectl delete -f /vagrant/k8s/app1-deployment.yaml
  echo "[INFO] Resources deleted."
else
  echo "[ERROR] Invalid argument. Usage: $0 {apply|delete}"
  exit 1
fi

