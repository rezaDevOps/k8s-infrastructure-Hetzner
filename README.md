# K8s Infrastructure - n8n & ArgoCD

Production-ready Kubernetes setup on Hetzner Cloud with K3s, n8n, and ArgoCD.

## Architecture

- **Platform**: K3s (Lightweight Kubernetes)
- **Cloud**: Hetzner Cloud (CPX21 recommended)
- **Domains**: 
  - n8n: https://n8n.awsdevzone.info
  - ArgoCD: https://argo.awsdevzone.info
- **Infrastructure**:
  - Traefik Ingress Controller
  - cert-manager for SSL/TLS
  - PostgreSQL for n8n database
  - ArgoCD for GitOps

## Prerequisites

- Hetzner Cloud server (CPX21: 4GB RAM, 2 vCPU)
- Domain configured in Cloudflare
- SSH access to server
- Git installed locally

## Quick Start

```bash
# 1. Clone this repository
git clone <your-repo-url>
cd k8s-infrastructure

# 2. Configure environment
cp config/.env.example config/.env
# Edit config/.env with your values

# 3. Update email in cert-manager issuer
nano base/cert-manager/letsencrypt-issuer.yaml
# Change: email: your-email@example.com

# 4. Run installation scripts in order
./scripts/01-install-k3s.sh
./scripts/02-install-cert-manager.sh
./scripts/03-install-traefik.sh
./scripts/04-setup-secrets.sh
./scripts/05-deploy-all.sh
./scripts/06-install-argocd.sh

# 5. Access your applications
# n8n: https://n8n.awsdevzone.info
# ArgoCD: https://argo.awsdevzone.info
```

## Project Structure

```
k8s-infrastructure/
├── scripts/         # Installation and maintenance scripts
├── base/           # Base configurations (cert-manager, traefik)
├── apps/           # Application manifests
│   ├── n8n/       # n8n deployment
│   └── argocd/    # ArgoCD deployment
├── config/        # Configuration files
└── docs/          # Documentation
```

## Cloudflare DNS Configuration

Configure these DNS records in Cloudflare:

```
Type     Name     Content              Proxy Status
─────────────────────────────────────────────────────
A        @        YOUR_HETZNER_IP      🟠 Proxied
CNAME    www      awsdevzone.info      🟠 Proxied
CNAME    n8n      awsdevzone.info      🟠 Proxied
CNAME    argo     awsdevzone.info      🟠 Proxied
```

**Cloudflare SSL/TLS Settings:**
- Encryption mode: **Full**
- Always Use HTTPS: **ON**
- TLS 1.3: **ON**

## Maintenance

```bash
# Backup n8n data
./scripts/backup.sh

# Monitor services
./scripts/monitor.sh

# Update n8n
kubectl rollout restart deployment/n8n -n n8n

# View logs
kubectl logs -f deployment/n8n -n n8n
```

## Documentation

- [Installation Guide](docs/installation.md)
- [Usage Guide](docs/usage.md)
- [Troubleshooting](docs/troubleshooting.md)

## Support

For issues, check the troubleshooting guide or open an issue.

## License

MIT License - Use freely for personal or commercial projects.
