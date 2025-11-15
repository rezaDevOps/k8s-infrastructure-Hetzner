#!/bin/bash
set -e

echo "🌐 Installing Traefik Ingress Controller..."

# Add Traefik Helm repository
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Create namespace
kubectl create namespace traefik --dry-run=client -o yaml | kubectl apply -f -

# Install Traefik
helm upgrade --install traefik traefik/traefik \
  -n traefik \
  -f base/traefik/values.yaml \
  --wait

echo "✅ Traefik installation complete!"
echo ""
echo "Verify with: kubectl get pods -n traefik"
echo "Get LoadBalancer IP: kubectl get svc -n traefik traefik"
