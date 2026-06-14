#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "[Server] Preparing host prerequisites..."
apt-get update -y && apt-get install -y curl

# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "[Server] Installing K3s Server..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --node-ip ${SERVER_IP} \
  --bind-address ${SERVER_IP} \
  --write-kubeconfig-mode 644" sh -

echo "[Server] Waiting for node-token to be generated..."
until [ -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

# Copy token to the synced folder
cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token
echo "[Server] K3s Server running"
