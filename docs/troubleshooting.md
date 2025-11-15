# Troubleshooting Guide

## Common Issues

### 1. Pods Not Starting

**Symptoms:** Pods stuck in `Pending`, `CrashLoopBackOff`, or `Error` state

**Diagnosis:**
```bash
kubectl get pods -n n8n
kubectl describe pod POD_NAME -n n8n
kubectl logs POD_NAME -n n8n
```

**Solutions:**

**If Pending:** Usually resource or storage issues
```bash
# Check node resources
kubectl describe nodes

# Check PVC status
kubectl get pvc -n n8n
kubectl describe pvc n8n-data -n n8n
```

**If CrashLoopBackOff:** Application error
```bash
# Check previous logs
kubectl logs POD_NAME -n n8n --previous

# Check configuration
kubectl describe deployment n8n -n n8n

# Verify secrets exist
kubectl get secrets -n n8n
```

### 2. SSL Certificate Issues

**Symptoms:** Certificate not issued, browser shows SSL error

**Diagnosis:**
```bash
kubectl get certificate -n n8n
kubectl describe certificate n8n-tls -n n8n
kubectl get certificaterequest -n n8n
kubectl describe certificaterequest CERT_REQUEST_NAME -n n8n
```

**Solutions:**

1. Check Let's Encrypt issuer:
```bash
kubectl describe clusterissuer letsencrypt-prod
```

2. Check cert-manager logs:
```bash
kubectl logs -n cert-manager -l app=cert-manager
```

3. Verify DNS is correct:
```bash
dig n8n.awsdevzone.info +short
# Should return Cloudflare IPs or your server IP
```

4. Delete and recreate certificate:
```bash
kubectl delete certificate n8n-tls -n n8n
# cert-manager will recreate it automatically
```

5. Check Cloudflare SSL mode:
   - Should be "Full" (not "Flexible" or "Full (strict)")

### 3. Cannot Access Applications

**Symptoms:** Timeout, connection refused, or 404 error

**Diagnosis:**
```bash
# Check ingress
kubectl get ingress -n n8n
kubectl describe ingress n8n -n n8n

# Check service
kubectl get svc -n n8n
kubectl describe svc n8n -n n8n

# Check if pod is ready
kubectl get pods -n n8n
```

**Solutions:**

1. Verify DNS:
```bash
nslookup n8n.awsdevzone.info
# Should show Cloudflare IPs
```

2. Check Traefik:
```bash
kubectl get pods -n traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik
```

3. Test from inside cluster:
```bash
kubectl run test --rm -it --image=curlimages/curl -- sh
curl http://n8n.n8n.svc.cluster.local
```

4. Check firewall:
```bash
sudo ufw status
# Should allow ports 80, 443, 22
```

5. Verify Cloudflare proxy is enabled (orange cloud 🟠)

### 4. PostgreSQL Connection Issues

**Symptoms:** n8n cannot connect to database

**Diagnosis:**
```bash
# Check PostgreSQL pod
kubectl get pods -n n8n -l app=postgres

# Check PostgreSQL logs
kubectl logs -n n8n -l app=postgres

# Test connection from n8n pod
kubectl exec -it deployment/n8n -n n8n -- sh
nc -zv postgres.n8n.svc.cluster.local 5432
```

**Solutions:**

1. Verify secrets:
```bash
kubectl get secret postgres-secret -n n8n -o yaml
```

2. Check PostgreSQL service:
```bash
kubectl get svc postgres -n n8n
kubectl describe svc postgres -n n8n
```

3. Restart PostgreSQL:
```bash
kubectl rollout restart statefulset/postgres -n n8n
```

4. Check environment variables in n8n:
```bash
kubectl exec -it deployment/n8n -n n8n -- env | grep DB_
```

### 5. ArgoCD Not Syncing

**Symptoms:** Application out of sync, sync fails

**Diagnosis:**
```bash
# Check application status
kubectl get application n8n -n argocd

# Describe application
kubectl describe application n8n -n argocd

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

**Solutions:**

1. Manual sync:
```bash
argocd app sync n8n
```

2. Check repository access:
```bash
argocd repo list
```

3. Refresh application:
```bash
argocd app get n8n --refresh
```

4. Verify Git repository URL in application manifest

### 6. n8n Workflows Not Executing

**Symptoms:** Workflows fail or don't start

**Diagnosis:**
```bash
# Check n8n logs
kubectl logs -f deployment/n8n -n n8n

# Check if n8n is healthy
kubectl exec -it deployment/n8n -n n8n -- wget -O- http://localhost:5678/healthz
```

**Solutions:**

1. Check database connection (see issue #4)
2. Verify n8n has enough resources:
```bash
kubectl top pod -n n8n
```
3. Increase resource limits if needed (edit n8n-deployment.yaml)
4. Restart n8n:
```bash
kubectl rollout restart deployment/n8n -n n8n
```

## Diagnostic Commands

### Full System Check

```bash
# Run monitor script
./scripts/monitor.sh

# Check all resources
kubectl get all -A

# Check events
kubectl get events -A --sort-by='.lastTimestamp'

# Check node status
kubectl describe nodes
```

### Network Debugging

```bash
# Test DNS resolution
kubectl run dnsutils --rm -it --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 -- sh
nslookup n8n.n8n.svc.cluster.local
nslookup postgres.n8n.svc.cluster.local

# Test service connectivity
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- sh
curl http://n8n.n8n.svc.cluster.local
nc -zv postgres.n8n.svc.cluster.local 5432
```

### Storage Issues

```bash
# Check PVC status
kubectl get pvc -A

# Check PV status
kubectl get pv

# Describe PVC
kubectl describe pvc n8n-data -n n8n

# Check disk usage on node
df -h
```

### Certificate Debugging

```bash
# Get certificate details
kubectl get certificate n8n-tls -n n8n -o yaml

# Check certificate status
kubectl describe certificate n8n-tls -n n8n

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f

# Test ACME challenge
kubectl get challenges -n n8n
```

## Recovery Procedures

### Restore from Backup

```bash
# Get PostgreSQL pod
POSTGRES_POD=$(kubectl get pod -n n8n -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# Copy backup to pod
kubectl cp backups/postgres_YYYYMMDD_HHMMSS.sql.gz n8n/$POSTGRES_POD:/tmp/backup.sql.gz

# Restore database
kubectl exec -it $POSTGRES_POD -n n8n -- bash -c "
  gunzip -c /tmp/backup.sql.gz | psql -U n8n_user -d n8n
"

# Restart n8n
kubectl rollout restart deployment/n8n -n n8n
```

### Complete Reset

**WARNING: This deletes all data!**

```bash
# Delete n8n namespace
kubectl delete namespace n8n

# Recreate from scratch
./scripts/04-setup-secrets.sh
./scripts/05-deploy-all.sh
```

### Reset ArgoCD Admin Password

```bash
# Delete the secret
kubectl -n argocd delete secret argocd-initial-admin-secret

# Restart argocd-server
kubectl -n argocd rollout restart deployment argocd-server

# Get new password (wait 30 seconds after restart)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Performance Issues

### n8n Running Slow

1. Check resource usage:
```bash
kubectl top pod -n n8n
kubectl describe pod -n n8n
```

2. Increase resources (edit apps/n8n/n8n-deployment.yaml):
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "1000m"
  limits:
    memory: "2Gi"
    cpu: "2000m"
```

3. Apply changes:
```bash
kubectl apply -f apps/n8n/n8n-deployment.yaml
```

### Database Performance Issues

1. Check database size:
```bash
POSTGRES_POD=$(kubectl get pod -n n8n -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POSTGRES_POD -n n8n -- psql -U n8n_user -d n8n -c "
SELECT 
    pg_size_pretty(pg_database_size('n8n')) as db_size,
    (SELECT count(*) FROM execution_entity) as executions;
"
```

2. Clean old executions (see Usage Guide)

3. Vacuum database:
```bash
kubectl exec -it $POSTGRES_POD -n n8n -- psql -U n8n_user -d n8n -c "VACUUM ANALYZE;"
```

## Getting Help

1. Check logs first:
```bash
kubectl logs -f deployment/n8n -n n8n
```

2. Review this troubleshooting guide

3. Search n8n community forum: https://community.n8n.io

4. Check Kubernetes documentation: https://kubernetes.io/docs/

5. Review cert-manager docs: https://cert-manager.io/docs/

6. Check ArgoCD docs: https://argo-cd.readthedocs.io/

## Emergency Contacts

- n8n Community: https://community.n8n.io
- Kubernetes Slack: https://kubernetes.slack.com
- Hetzner Support: https://console.hetzner.cloud
