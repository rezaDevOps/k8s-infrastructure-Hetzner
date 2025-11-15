# Installation Guide

## Prerequisites

1. **Hetzner Cloud Server**
   - Minimum: CPX21 (4GB RAM, 2 vCPU, 80GB SSD)
   - OS: Ubuntu 22.04 LTS
   - Public IPv4 address

2. **Domain Configuration**
   - Domain registered (awsdevzone.info)
   - DNS managed by Cloudflare
   - CNAME records configured:
     - n8n.awsdevzone.info → awsdevzone.info (Proxied)
     - argo.awsdevzone.info → awsdevzone.info (Proxied)
   - Root A record: @ → YOUR_HETZNER_IP (Proxied)

3. **Local Tools**
   - Git
   - SSH client
   - Text editor

## Cloudflare DNS Setup

In Cloudflare Dashboard → DNS → Records:

```
Type     Name     Content              Proxy Status    TTL
──────────────────────────────────────────────────────────────
A        @        YOUR_HETZNER_IP      🟠 Proxied      Auto
CNAME    www      awsdevzone.info      🟠 Proxied      Auto
CNAME    n8n      awsdevzone.info      🟠 Proxied      Auto
CNAME    argo     awsdevzone.info      🟠 Proxied      Auto
```

**Cloudflare SSL/TLS Settings:**
- SSL/TLS → Overview → Encryption mode: **Full**
- SSL/TLS → Edge Certificates → Always Use HTTPS: **ON**

## Step-by-Step Installation

### 1. Prepare Your Server

```bash
# SSH into your server
ssh root@YOUR_SERVER_IP

# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y curl git
```

### 2. Clone Repository

```bash
cd /opt
git clone https://github.com/YOUR_USERNAME/k8s-infrastructure.git
cd k8s-infrastructure
```

### 3. Configure Environment

```bash
# The .env file already has secure generated passwords
# Just update the email for Let's Encrypt

# Edit cert-manager issuer
nano base/cert-manager/letsencrypt-issuer.yaml
# Change: email: your-email@example.com to your actual email

# Verify .env has values
cat config/.env
```

### 4. Run Installation Scripts

```bash
# Install K3s
./scripts/01-install-k3s.sh

# Install cert-manager
./scripts/02-install-cert-manager.sh

# Install Traefik
./scripts/03-install-traefik.sh

# Setup secrets
./scripts/04-setup-secrets.sh

# Deploy n8n
./scripts/05-deploy-all.sh

# Install ArgoCD
./scripts/06-install-argocd.sh
```

### 5. Verify Installation

```bash
# Check all pods are running
kubectl get pods -A

# Check n8n
kubectl get all -n n8n

# Check ingress
kubectl get ingress -n n8n
kubectl get ingress -n argocd

# Check certificates (may take 1-2 minutes to issue)
kubectl get certificate -n n8n
kubectl get certificate -n argocd
```

### 6. Access Applications

**n8n:**
- URL: https://n8n.awsdevzone.info
- Username: admin
- Password: (from config/.env - N8N_BASIC_AUTH_PASSWORD)

**ArgoCD:**
- URL: https://argo.awsdevzone.info
- Username: admin
- Password: (printed by script 06, or run):
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

## Troubleshooting

If something doesn't work:

1. Check pod status:
   ```bash
   kubectl get pods -A
   kubectl describe pod POD_NAME -n NAMESPACE
   ```

2. Check logs:
   ```bash
   kubectl logs -f deployment/n8n -n n8n
   ```

3. Check certificates:
   ```bash
   kubectl describe certificate n8n-tls -n n8n
   ```

4. Verify DNS:
   ```bash
   dig n8n.awsdevzone.info +short
   dig argo.awsdevzone.info +short
   ```

See [Troubleshooting Guide](troubleshooting.md) for more details.

## Next Steps

1. Setup automated backups (see [Usage Guide](usage.md))
2. Configure ArgoCD to watch your Git repository
3. Create your first n8n workflow
4. Setup monitoring (optional)
