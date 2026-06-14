#!/bin/bash

# provision smargineS VM with K3s in server mode

echo "[INFO] Updating system..."
apt-get update
apt-get install -y curl

echo "[INFO] Installing K3s in server mode..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --node-ip ${SERVER_IP} \
  --bind-address ${SERVER_IP} \
  --write-kubeconfig-mode 644" sh -

echo "[INFO] Waiting for K3s to be ready..."
for i in {1..30}; do
    if sudo systemctl is-active --quiet k3s; then
        echo "[INFO] K3s is active"
        break
    fi
    echo "[INFO] Waiting for K3s ($i/30)..."
    sleep 2
done

echo "[INFO] Checking K3s status..."
systemctl status k3s --no-pager

echo "[INFO] Done. You can now run 'kubectl get nodes -o wide' after SSH into the VM."
