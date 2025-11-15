#!/bin/bash
set -e

# Load environment variables
if [ ! -f config/.env ]; then
    echo "❌ Error: config/.env not found!"
    echo "Copy config/.env.example to config/.env and configure it first."
    exit 1
fi

source config/.env

echo "🔑 Creating Kubernetes secrets..."

# Create n8n namespace
kubectl create namespace n8n --dry-run=client -o yaml | kubectl apply -f -

# Create PostgreSQL secret
kubectl create secret generic postgres-secret -n n8n \
  --from-literal=POSTGRES_USER="${POSTGRES_USER}" \
  --from-literal=POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
  --from-literal=POSTGRES_DB="${POSTGRES_DB}" \
  --dry-run=client -o yaml | kubectl apply -f -

# Create n8n secret
kubectl create secret generic n8n-secret -n n8n \
  --from-literal=N8N_BASIC_AUTH_USER="${N8N_USER}" \
  --from-literal=N8N_BASIC_AUTH_PASSWORD="${N8N_BASIC_AUTH_PASSWORD}" \
  --from-literal=N8N_ENCRYPTION_KEY="${N8N_ENCRYPTION_KEY}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secrets created successfully!"
echo ""
echo "Verify with: kubectl get secrets -n n8n"
