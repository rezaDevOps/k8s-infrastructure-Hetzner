# Usage Guide

## Daily Operations

### Monitoring

Run the monitoring script to check system status:

```bash
./scripts/monitor.sh
```

This displays:
- Node status
- All pods status
- Ingress configuration
- Certificate status
- Recent logs
- Application health checks

### Backup

Run daily backups:

```bash
./scripts/backup.sh
```

Backups are stored in `./backups/` directory.

**Schedule automatic backups:**
```bash
# Add to crontab
crontab -e

# Add this line for daily backup at 2 AM
0 2 * * * cd /opt/k8s-infrastructure && ./scripts/backup.sh >> ./backups/backup.log 2>&1
```

### Updating n8n

```bash
# Pull latest image
kubectl set image deployment/n8n n8n=n8nio/n8n:latest -n n8n

# Or restart deployment
kubectl rollout restart deployment/n8n -n n8n

# Watch rollout
kubectl rollout status deployment/n8n -n n8n
```

### Viewing Logs

```bash
# n8n logs
kubectl logs -f deployment/n8n -n n8n

# PostgreSQL logs
kubectl logs -f statefulset/postgres -n n8n

# Traefik logs
kubectl logs -f deployment/traefik -n traefik

# ArgoCD logs
kubectl logs -f deployment/argocd-server -n argocd
```

### Scaling n8n

```bash
# Scale to 2 replicas
kubectl scale deployment n8n -n n8n --replicas=2

# Scale back to 1
kubectl scale deployment n8n -n n8n --replicas=1
```

## ArgoCD GitOps Workflow

### Setup Git Repository

1. Push this repository to GitHub/GitLab:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/k8s-infrastructure.git
   git push -u origin main
   ```

2. Update ArgoCD application:
   ```bash
   # Edit apps/argocd/applications/n8n-app.yaml
   # Update the repoURL to your Git repository
   
   kubectl apply -f apps/argocd/applications/n8n-app.yaml
   ```

### Making Changes via GitOps

1. Edit manifests locally:
   ```bash
   # Example: Update n8n image version
   nano apps/n8n/n8n-deployment.yaml
   ```

2. Commit and push:
   ```bash
   git add .
   git commit -m "Update n8n configuration"
   git push
   ```

3. ArgoCD will automatically sync changes (if auto-sync enabled)
   
   Or manually sync:
   ```bash
   argocd app sync n8n
   ```

## Common Tasks

### Restart All Services

```bash
kubectl rollout restart deployment/n8n -n n8n
kubectl rollout restart statefulset/postgres -n n8n
```

### Check Resource Usage

```bash
# Overall cluster resources
kubectl top nodes

# n8n namespace resources
kubectl top pods -n n8n

# Specific pod
kubectl top pod POD_NAME -n n8n
```

### Database Access

```bash
# Get PostgreSQL pod name
POSTGRES_POD=$(kubectl get pod -n n8n -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# Access PostgreSQL
kubectl exec -it $POSTGRES_POD -n n8n -- psql -U n8n_user -d n8n

# Run SQL query
kubectl exec -it $POSTGRES_POD -n n8n -- psql -U n8n_user -d n8n -c "SELECT * FROM workflow_entity;"
```

### Clean Old Executions

```bash
# Delete executions older than 30 days
POSTGRES_POD=$(kubectl get pod -n n8n -l app=postgres -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it $POSTGRES_POD -n n8n -- psql -U n8n_user -d n8n -c "
DELETE FROM execution_entity 
WHERE \"stoppedAt\" < NOW() - INTERVAL '30 days';
VACUUM ANALYZE;
"
```

## Security

### Rotate Passwords

1. Generate new passwords:
   ```bash
   NEW_PASSWORD=$(openssl rand -base64 24)
   echo $NEW_PASSWORD
   ```

2. Update secrets:
   ```bash
   # Update n8n password
   kubectl create secret generic n8n-secret -n n8n \
     --from-literal=N8N_BASIC_AUTH_USER=admin \
     --from-literal=N8N_BASIC_AUTH_PASSWORD=$NEW_PASSWORD \
     --from-literal=N8N_ENCRYPTION_KEY=$(kubectl get secret n8n-secret -n n8n -o jsonpath='{.data.N8N_ENCRYPTION_KEY}' | base64 -d) \
     --dry-run=client -o yaml | kubectl apply -f -
   
   # Restart n8n
   kubectl rollout restart deployment/n8n -n n8n
   ```

### Update SSL Certificates

Certificates are automatically renewed by cert-manager.

To manually trigger renewal:
```bash
kubectl delete certificate n8n-tls -n n8n
kubectl delete certificate argocd-tls -n argocd

# cert-manager will automatically recreate them
```

## Maintenance

### Update Kubernetes Components

```bash
# Update Traefik
helm repo update
helm upgrade traefik traefik/traefik -n traefik -f base/traefik/values.yaml

# Update cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Update ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Cleanup

```bash
# Remove old container images
kubectl delete pod --field-selector=status.phase==Succeeded -A

# Clean up completed jobs
kubectl delete jobs --field-selector=status.successful=1 -A
```

## Useful Commands

### Quick Status Check

```bash
# All resources in n8n namespace
kubectl get all -n n8n

# Watch pods
watch kubectl get pods -n n8n

# Events
kubectl get events -n n8n --sort-by='.lastTimestamp'
```

### Port Forwarding (for debugging)

```bash
# Access n8n locally (bypass ingress)
kubectl port-forward -n n8n deployment/n8n 5678:5678
# Then open: http://localhost:5678

# Access PostgreSQL locally
kubectl port-forward -n n8n statefulset/postgres 5432:5432
# Then connect: psql -h localhost -U n8n_user -d n8n
```

### Get All Secrets

```bash
kubectl get secrets -n n8n
kubectl get secret n8n-secret -n n8n -o yaml
```

## ArgoCD Management

### Login to ArgoCD CLI

```bash
# Get password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Login
argocd login argo.awsdevzone.info --username admin --password $ARGOCD_PASSWORD
```

### ArgoCD Commands

```bash
# List applications
argocd app list

# Get application details
argocd app get n8n

# Sync application
argocd app sync n8n

# Refresh application
argocd app get n8n --refresh

# Delete application
argocd app delete n8n
```
