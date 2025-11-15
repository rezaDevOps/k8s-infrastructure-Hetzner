#!/bin/bash
set -e

echo "🚀 Deploying all applications..."

# Deploy n8n
echo "📦 Deploying n8n..."
kubectl apply -k apps/n8n/

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL..."
kubectl wait --for=condition=ready pod \
  -l app=postgres \
  -n n8n \
  --timeout=300s

# Wait for n8n to be ready
echo "⏳ Waiting for n8n..."
kubectl wait --for=condition=ready pod \
  -l app=n8n \
  -n n8n \
  --timeout=300s

echo "✅ Deployment complete!"
echo ""
echo "Access n8n at: https://n8n.awsdevzone.info"
echo ""
echo "Check status:"
echo "  kubectl get all -n n8n"
echo "  kubectl get ingress -n n8n"
echo "  kubectl get certificate -n n8n"
