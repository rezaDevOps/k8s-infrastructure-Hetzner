#!/bin/bash

echo "📊 K8s Infrastructure Status"
echo "=============================="
echo ""

echo "🖥️  Nodes:"
kubectl get nodes
echo ""

echo "📦 Namespaces:"
kubectl get namespaces
echo ""

echo "🔧 n8n Status:"
kubectl get all -n n8n
echo ""

echo "🌐 Ingress:"
kubectl get ingress -n n8n
kubectl get ingress -n argocd
echo ""

echo "🔐 Certificates:"
kubectl get certificate -n n8n
kubectl get certificate -n argocd
echo ""

echo "💾 Storage:"
kubectl get pvc -n n8n
echo ""

echo "🔍 Recent n8n logs (last 10 lines):"
kubectl logs -n n8n deployment/n8n --tail=10
echo ""

# Check if n8n is responding
if curl -sf https://n8n.awsdevzone.info > /dev/null 2>&1; then
    echo "✅ n8n is UP and responding"
else
    echo "❌ n8n is DOWN or not responding"
fi

# Check if ArgoCD is responding
if curl -sf https://argo.awsdevzone.info > /dev/null 2>&1; then
    echo "✅ ArgoCD is UP and responding"
else
    echo "❌ ArgoCD is DOWN or not responding"
fi
