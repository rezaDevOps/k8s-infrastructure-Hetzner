#!/bin/bash

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

mkdir -p $BACKUP_DIR

echo "🔄 Starting backup - $DATE"

# Get PostgreSQL pod name
POSTGRES_POD=$(kubectl get pod -n n8n -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# Load environment
source config/.env

# Backup PostgreSQL
echo "📦 Backing up PostgreSQL..."
kubectl exec -n n8n $POSTGRES_POD -- pg_dump -U $POSTGRES_USER $POSTGRES_DB | gzip > $BACKUP_DIR/postgres_$DATE.sql.gz

# Backup n8n PVC data
echo "📦 Backing up n8n data..."
kubectl get pvc n8n-data -n n8n -o yaml > $BACKUP_DIR/n8n-pvc_$DATE.yaml

# Remove old backups
find $BACKUP_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.yaml" -mtime +$RETENTION_DAYS -delete

echo "✅ Backup completed: $DATE"
echo "📁 Backup location: $BACKUP_DIR"
ls -lh $BACKUP_DIR/ | tail -5
