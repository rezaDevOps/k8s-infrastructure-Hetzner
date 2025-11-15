# Project Structure

Complete directory structure and file descriptions.

## Directory Tree

```
k8s-infrastructure/
├── README.md                      # Main project documentation
├── QUICKSTART.md                  # 15-minute deployment guide
├── .gitignore                     # Git ignore rules
│
├── scripts/                       # Installation and maintenance scripts
│   ├── 01-install-k3s.sh         # Install K3s cluster
│   ├── 02-install-cert-manager.sh # Install cert-manager for SSL
│   ├── 03-install-traefik.sh     # Install Traefik ingress
│   ├── 04-setup-secrets.sh       # Create Kubernetes secrets
│   ├── 05-deploy-all.sh          # Deploy n8n application
│   ├── 06-install-argocd.sh      # Install ArgoCD
│   ├── backup.sh                 # Backup PostgreSQL and n8n data
│   └── monitor.sh                # Monitor cluster health
│
├── base/                          # Base infrastructure configurations
│   ├── cert-manager/
│   │   └── letsencrypt-issuer.yaml  # Let's Encrypt ClusterIssuer
│   └── traefik/
│       └── values.yaml           # Traefik Helm chart values
│
├── apps/                          # Application manifests
│   ├── n8n/
│   │   ├── kustomization.yaml    # Kustomize configuration
│   │   ├── namespace.yaml        # n8n namespace
│   │   ├── postgres-statefulset.yaml  # PostgreSQL StatefulSet
│   │   ├── n8n-deployment.yaml   # n8n Deployment
│   │   ├── n8n-service.yaml      # n8n Service
│   │   ├── n8n-ingress.yaml      # n8n Ingress (HTTPS)
│   │   └── secrets.example.yaml  # Example secrets file
│   │
│   └── argocd/
│       ├── ingress.yaml          # ArgoCD Ingress (HTTPS)
│       └── applications/
│           └── n8n-app.yaml      # ArgoCD Application for n8n
│
├── config/                        # Configuration files
│   ├── .env                      # Environment variables (generated with secure passwords)
│   └── .env.example              # Example environment file
│
└── docs/                          # Documentation
    ├── installation.md           # Detailed installation guide
    ├── usage.md                  # Usage and operations guide
    └── troubleshooting.md        # Troubleshooting guide
```

## File Descriptions

### Root Files

- **README.md**: Main project overview, quick start, and links to documentation
- **QUICKSTART.md**: Step-by-step 15-minute deployment guide
- **.gitignore**: Prevents committing sensitive files (secrets, backups, .env)

### Scripts (`scripts/`)

All scripts are executable (`chmod +x`) and should be run in order:

1. **01-install-k3s.sh**: Installs K3s (lightweight Kubernetes) and Helm
2. **02-install-cert-manager.sh**: Installs cert-manager for automatic SSL certificates
3. **03-install-traefik.sh**: Installs Traefik as the ingress controller
4. **04-setup-secrets.sh**: Creates Kubernetes secrets from config/.env
5. **05-deploy-all.sh**: Deploys n8n and PostgreSQL to the cluster
6. **06-install-argocd.sh**: Installs ArgoCD for GitOps workflows
7. **backup.sh**: Backs up PostgreSQL database and n8n data (schedule with cron)
8. **monitor.sh**: Displays cluster health and application status

### Base Configurations (`base/`)

Infrastructure-level configurations:

- **cert-manager/letsencrypt-issuer.yaml**: ClusterIssuer for Let's Encrypt SSL certificates
- **traefik/values.yaml**: Helm values for Traefik ingress controller configuration

### Applications (`apps/`)

#### n8n (`apps/n8n/`)

Complete n8n deployment with PostgreSQL:

- **kustomization.yaml**: Kustomize config that ties all manifests together
- **namespace.yaml**: Creates the 'n8n' namespace
- **postgres-statefulset.yaml**: PostgreSQL database (StatefulSet with persistent storage)
- **n8n-deployment.yaml**: n8n application deployment with environment variables
- **n8n-service.yaml**: Kubernetes Service exposing n8n internally
- **n8n-ingress.yaml**: Ingress configuration for https://n8n.awsdevzone.info
- **secrets.example.yaml**: Example of secret structure (DO NOT commit real secrets)

#### ArgoCD (`apps/argocd/`)

GitOps deployment management:

- **ingress.yaml**: Ingress configuration for https://argo.awsdevzone.info
- **applications/n8n-app.yaml**: ArgoCD Application manifest to manage n8n via GitOps

### Configuration (`config/`)

- **.env**: Environment variables with generated secure passwords
  - PostgreSQL credentials
  - n8n authentication
  - Encryption keys
  - Domain configuration
- **.env.example**: Template for .env file

### Documentation (`docs/`)

- **installation.md**: Complete installation guide with prerequisites, step-by-step instructions, and verification
- **usage.md**: Daily operations, maintenance tasks, ArgoCD workflows, and common commands
- **troubleshooting.md**: Solutions for common issues, diagnostic commands, and recovery procedures

## Key Technologies

- **K3s**: Lightweight Kubernetes distribution
- **Helm**: Kubernetes package manager
- **Kustomize**: Kubernetes native configuration management
- **Traefik**: Modern HTTP reverse proxy and load balancer
- **cert-manager**: Automatic SSL/TLS certificate management
- **ArgoCD**: Declarative GitOps continuous delivery for Kubernetes
- **PostgreSQL**: Relational database for n8n
- **n8n**: Workflow automation platform

## Environment Variables

Located in `config/.env`:

```bash
# PostgreSQL
POSTGRES_USER=n8n_user
POSTGRES_PASSWORD=<auto-generated>
POSTGRES_DB=n8n

# n8n Authentication
N8N_USER=admin
N8N_BASIC_AUTH_PASSWORD=<auto-generated>
N8N_ENCRYPTION_KEY=<auto-generated>

# Domains
N8N_DOMAIN=n8n.awsdevzone.info
ARGOCD_DOMAIN=argo.awsdevzone.info

# Let's Encrypt
LETSENCRYPT_EMAIL=your-email@example.com
```

## Kubernetes Resources Created

After full deployment:

### Namespaces
- `n8n` - n8n application
- `argocd` - ArgoCD
- `traefik` - Traefik ingress controller
- `cert-manager` - Certificate management

### Persistent Storage
- `postgres-storage` - PostgreSQL data (10Gi)
- `n8n-data` - n8n workflows and credentials (5Gi)

### Secrets
- `postgres-secret` - PostgreSQL credentials
- `n8n-secret` - n8n authentication and encryption key

### Services
- n8n (ClusterIP on port 80)
- PostgreSQL (ClusterIP on port 5432)
- Traefik (LoadBalancer on ports 80, 443)
- ArgoCD Server (ClusterIP)

### Ingress Routes
- `https://n8n.awsdevzone.info` → n8n service
- `https://argo.awsdevzone.info` → ArgoCD service

### Certificates
- `n8n-tls` - SSL certificate for n8n
- `argocd-tls` - SSL certificate for ArgoCD

## Security Considerations

1. **Secrets Management**: 
   - Never commit `config/.env` to Git
   - Secrets are stored in Kubernetes secrets (base64 encoded)
   - Use strong auto-generated passwords

2. **Network Security**:
   - Basic authentication on n8n
   - TLS/SSL encryption via Let's Encrypt
   - Cloudflare DDoS protection (optional)

3. **Access Control**:
   - n8n: Basic auth (username/password)
   - ArgoCD: Admin password (can configure RBAC)
   - PostgreSQL: Only accessible within cluster

## Backup Strategy

The `backup.sh` script creates:
- PostgreSQL database dump (gzipped SQL)
- n8n data volume backup (YAML)
- Automatic retention (7 days by default)

Store in: `./backups/`

Schedule: `0 2 * * *` (2 AM daily via cron)

## GitOps Workflow

1. Make changes to manifests in `apps/`
2. Commit and push to Git repository
3. ArgoCD automatically syncs changes to cluster
4. Or manually sync: `argocd app sync n8n`

## Resource Requirements

### Minimum (Development)
- 2 vCPU
- 4GB RAM
- 40GB SSD
- Cost: ~€7.59/month (Hetzner CPX21)

### Recommended (Production)
- 4 vCPU
- 8GB RAM
- 80GB SSD
- Cost: ~€13.90/month (Hetzner CPX31)

## URLs

After deployment, access:

- **n8n**: https://n8n.awsdevzone.info
- **ArgoCD**: https://argo.awsdevzone.info

## Support

For help:
1. Check [Troubleshooting Guide](docs/troubleshooting.md)
2. Review [Usage Guide](docs/usage.md)
3. Visit [n8n Community](https://community.n8n.io)
4. Check [ArgoCD Documentation](https://argo-cd.readthedocs.io)
