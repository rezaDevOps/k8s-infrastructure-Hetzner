#!/bin/bash
set -e

echo "🚀 Installing K3s..."

# Install K3s without default Traefik (we'll install our own)
curl -sfL https://get.k3s.io | sh -s - \
  --write-kubeconfig-mode 644 \
  --disable traefik

# Wait for K3s to be ready
echo "⏳ Waiting for K3s to be ready..."
sleep 30

# Verify installation
kubectl get nodes

# Install Helm
echo "📦 Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "✅ K3s installation complete!"
echo ""
echo "Verify with: kubectl get nodes"
