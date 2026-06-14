#!/usr/bin/env bash

set -e

k3d cluster create iot-cluster --api-port 6550 -p "8888:80@loadbalancer" --agents 1
kubectl apply -f ~/mnt/p3/confs/namespaces.yaml
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f ~/mnt/p3/confs/argocd-app.yaml
