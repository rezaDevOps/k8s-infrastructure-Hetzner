#!/bin/bash
set -e

echo "🔐 Installing cert-manager..."

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Wait for cert-manager to be ready
echo "⏳ Waiting for cert-manager pods..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/instance=cert-manager \
  -n cert-manager \
  --timeout=300s

# Apply Let's Encrypt issuer
kubectl apply -f base/cert-manager/letsencrypt-issuer.yaml

echo "✅ cert-manager installation complete!"
echo ""
echo "Verify with: kubectl get pods -n cert-manager"
