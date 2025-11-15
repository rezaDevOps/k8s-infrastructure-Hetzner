# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a production-ready Kubernetes infrastructure repository for deploying n8n workflow automation and ArgoCD on Hetzner Cloud using K3s. The project follows a GitOps approach with automated deployments.

**Target Platform**: Hetzner Cloud CPX21 (4GB RAM, 2 vCPU, ~€7.59/month)
**Domains**: n8n.awsdevzone.info, argo.awsdevzone.info

## Installation Commands

Scripts must be run **in order** on the Hetzner server:

```bash
# Sequential installation (do not run in parallel)
./scripts/01-install-k3s.sh          # Installs K3s with --disable traefik, installs Helm
./scripts/02-install-cert-manager.sh # Installs cert-manager via Helm
./scripts/03-install-traefik.sh      # Installs Traefik via Helm with custom values
./scripts/04-setup-secrets.sh        # Creates K8s secrets from config/.env
./scripts/05-deploy-all.sh           # Deploys n8n via Kustomize
./scripts/06-install-argocd.sh       # Installs ArgoCD and configures ingress

# Maintenance
./scripts/backup.sh                  # Backup PostgreSQL + n8n data
./scripts/monitor.sh                 # Display cluster health
```

## Key Architecture Decisions

### Secret Management
- **Never** commit `config/.env` to Git (already in .gitignore)
- Secrets are created via `04-setup-secrets.sh` which sources `config/.env`
- Two Kubernetes secrets created in `n8n` namespace:
  - `postgres-secret`: PostgreSQL credentials
  - `n8n-secret`: n8n auth + encryption key

### Kustomize-Based Deployment
- n8n deployment uses Kustomize (not raw kubectl apply)
- Deploy with: `kubectl apply -k apps/n8n/`
- All resources defined in `apps/n8n/kustomization.yaml`

### GitOps with ArgoCD
- ArgoCD Application manifest: `apps/argocd/applications/n8n-app.yaml`
- Must update `repoURL` to your actual Git repository
- Auto-sync enabled with prune and self-heal
- ArgoCD manages n8n deployment from the `apps/n8n/` directory

### Ingress Strategy
- Traefik is the ingress controller (K3s default Traefik is disabled)
- cert-manager handles automatic Let's Encrypt SSL certificates
- Two Ingress resources:
  - `apps/n8n/n8n-ingress.yaml` (n8n.awsdevzone.info)
  - `apps/argocd/ingress.yaml` (argo.awsdevzone.info)
- Both use `letsencrypt-prod` ClusterIssuer

### Storage Architecture
- PostgreSQL: StatefulSet with PVC (`postgres-storage`, 10Gi)
- n8n: Deployment with PVC for persistent data (5Gi)
- Uses K3s default local-path storage class

## Common Development Tasks

### Testing Changes Locally
```bash
# Validate Kubernetes manifests
kubectl apply --dry-run=client -k apps/n8n/

# View rendered Kustomize output
kubectl kustomize apps/n8n/
```

### Updating n8n Deployment
```bash
# After editing manifests in apps/n8n/
kubectl apply -k apps/n8n/

# Or let ArgoCD sync automatically (if configured)
# Check sync status: kubectl get applications -n argocd
```

### Viewing Logs
```bash
kubectl logs -f deployment/n8n -n n8n
kubectl logs -f statefulset/postgres -n n8n
kubectl logs -f -n traefik deployment/traefik
```

### Certificate Troubleshooting
```bash
# Check certificate status
kubectl get certificate -A
kubectl describe certificate n8n-tls -n n8n

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

### ArgoCD Operations
```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Sync application manually
argocd app sync n8n

# Check application health
argocd app get n8n
```

## Important Configuration Files

### Must Update Before Deployment
1. `base/cert-manager/letsencrypt-issuer.yaml` - Change email address
2. `config/.env` - Copy from `.env.example` and set strong passwords
3. `apps/argocd/applications/n8n-app.yaml` - Update `repoURL` to your Git repository

### Domain Configuration
Domains are hardcoded in:
- `apps/n8n/n8n-ingress.yaml` (host: n8n.awsdevzone.info)
- `apps/argocd/ingress.yaml` (host: argo.awsdevzone.info)
- `apps/n8n/n8n-deployment.yaml` (WEBHOOK_URL environment variable)

To use different domains, update these files before deployment.

## Namespace Structure

- `n8n` - n8n application and PostgreSQL
- `argocd` - ArgoCD GitOps controller
- `traefik` - Traefik ingress controller
- `cert-manager` - Certificate management

## Backup and Recovery

Backup script creates:
- PostgreSQL dump: `kubectl exec postgres-0 -n n8n -- pg_dump`
- n8n PVC data: `kubectl get pvc -n n8n`
- Stored in `./backups/` directory

Recommended cron: `0 2 * * * cd /opt/k8s-infrastructure && ./scripts/backup.sh`

## Cloudflare Integration

DNS records must be configured in Cloudflare with **Proxy Status: Proxied**
SSL/TLS mode must be set to **Full** (not Flexible) to work with Let's Encrypt certificates

## Access Credentials

**n8n**:
- Username: From `N8N_USER` in config/.env (default: admin)
- Password: From `N8N_BASIC_AUTH_PASSWORD` in config/.env

**ArgoCD**:
- Username: admin
- Password: Retrieved via `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
