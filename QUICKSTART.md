# Quick Start Guide

## 🚀 Deploy n8n + ArgoCD on Hetzner in 15 Minutes

This guide gets you from zero to production-ready n8n and ArgoCD deployment.

## Prerequisites ✅

- [ ] Hetzner Cloud account
- [ ] Domain name (e.g., awsdevzone.info)
- [ ] Cloudflare account (free)
- [ ] SSH access to your server

## Step 1: Create Hetzner Server (5 min)

1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud)
2. Create new project
3. Add server:
   - **Location**: Nuremberg (or closest to you)
   - **Image**: Ubuntu 22.04
   - **Type**: CPX21 (4GB RAM, 2 vCPU) - **€7.59/month**
   - **SSH Key**: Add your SSH key
   - **Name**: k8s-n8n
4. Note your server's **public IP address**

## Step 2: Configure Cloudflare DNS (3 min)

1. Add your domain to Cloudflare (free plan)
2. Update nameservers at your domain registrar
3. In Cloudflare DNS, add these records:

```
Type     Name     Content              Proxy Status
──────────────────────────────────────────────────────
A        @        YOUR_HETZNER_IP      🟠 Proxied
CNAME    n8n      awsdevzone.info      🟠 Proxied
CNAME    argo     awsdevzone.info      🟠 Proxied
```

4. SSL/TLS Settings:
   - **Encryption mode**: Full
   - **Always Use HTTPS**: ON

## Step 3: Deploy on Server (7 min)

### SSH into your server
```bash
ssh root@YOUR_HETZNER_IP
```

### Clone and configure
```bash
# Navigate to /opt
cd /opt

# Clone repository (or upload your local copy)
git clone https://github.com/YOUR_USERNAME/k8s-infrastructure.git
cd k8s-infrastructure

# Update Let's Encrypt email
nano base/cert-manager/letsencrypt-issuer.yaml
# Change: email: your-email@example.com

# View your generated secure passwords
cat config/.env
```

### Install everything
```bash
# Run all installation scripts
./scripts/01-install-k3s.sh         # ~2 min
./scripts/02-install-cert-manager.sh # ~1 min
./scripts/03-install-traefik.sh      # ~1 min
./scripts/04-setup-secrets.sh        # ~10 sec
./scripts/05-deploy-all.sh           # ~2 min
./scripts/06-install-argocd.sh       # ~1 min
```

## Step 4: Access Your Applications! 🎉

### n8n
```
URL: https://n8n.awsdevzone.info
Username: admin
Password: (from config/.env - N8N_BASIC_AUTH_PASSWORD)
```

### ArgoCD
```
URL: https://argo.awsdevzone.info
Username: admin
Password: (shown after installation, or run):
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Verify Everything Works

```bash
# Check all pods are running
kubectl get pods -A

# Run monitor script
./scripts/monitor.sh

# Check URLs
curl -I https://n8n.awsdevzone.info
curl -I https://argo.awsdevzone.info
```

## What You Just Built 🏗️

✅ **Production-grade Kubernetes cluster** (K3s)
✅ **n8n workflow automation** with PostgreSQL
✅ **ArgoCD** for GitOps deployments
✅ **Automatic SSL certificates** (Let's Encrypt)
✅ **DDoS protection** (Cloudflare)
✅ **Secure** with basic auth and encrypted secrets

## Monthly Cost 💰

```
Hetzner CPX21:     €7.59/month
Domain:            ~€1/month
Cloudflare:        FREE
SSL Certificate:   FREE
Total:             ~€8.59/month ($9.40)
```

## Next Steps

1. **Backup Setup**: Schedule automated backups
   ```bash
   crontab -e
   # Add: 0 2 * * * cd /opt/k8s-infrastructure && ./scripts/backup.sh
   ```

2. **Create n8n Workflows**: Start automating!

3. **GitOps Setup**: Push to GitHub and configure ArgoCD

4. **Monitoring**: Add Prometheus/Grafana (optional)

## Need Help?

- 📖 Full docs: [docs/installation.md](docs/installation.md)
- 🔧 Troubleshooting: [docs/troubleshooting.md](docs/troubleshooting.md)
- 💡 Usage guide: [docs/usage.md](docs/usage.md)

## Common Issues

### Can't access n8n or ArgoCD?
```bash
# Check DNS propagation
dig n8n.awsdevzone.info +short

# Check pods
kubectl get pods -A

# Check certificates (wait 1-2 min for issuance)
kubectl get certificate -A
```

### Pods not starting?
```bash
# Check events
kubectl get events -n n8n --sort-by='.lastTimestamp'

# Check specific pod
kubectl describe pod POD_NAME -n n8n
```

---

**Congratulations! 🎉 You now have a production-ready automation platform!**

Start creating workflows at: **https://n8n.awsdevzone.info**
