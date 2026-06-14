#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "[Worker] Preparing host prerequisites..."
apt-get update -y && apt-get install -y curl

# Disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Loop until the token file appears in the synced directory
echo "[Worker] Waiting for cluster token from server..."
until [ -f /vagrant/node-token ]; do
  sleep 2
done

# Install K3s agent
echo "[Worker] Installing K3s Agent and joining cluster..."
curl -sfL https://get.k3s.io | K3S_URL="https://${SERVER_IP}:6443" \
  K3S_TOKEN_FILE="/vagrant/node-token" \
  INSTALL_K3S_EXEC="agent --node-ip ${WORKER_IP}" sh -

echo "[Worker] K3s Agent joined the server"
