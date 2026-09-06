#!/bin/bash
# Complete deployment script for BankApp with Let's Encrypt and Gateway API
# Usage: ./deploy-bankapp.sh <domain> <email> [staging|prod]

set -e

DOMAIN="${1:-bankapp.example.com}"
EMAIL="${2:-admin@bankapp.example.com}"
ISSUER="${3:-letsencrypt-staging}"
NAMESPACE="bankapp"
CERT_MANAGER_NAMESPACE="cert-manager"
INGRESS_NAMESPACE="ingress-nginx"

echo "🚀 Starting BankApp Deployment"
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"
echo "Issuer: $ISSUER"
echo "================================"

# Step 1: Deploy Cert-Manager
echo "📦 Step 1: Installing Cert-Manager..."
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace $CERT_MANAGER_NAMESPACE \
  --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true \
  --set global.leaderElection.namespace=$CERT_MANAGER_NAMESPACE \
  --set serviceAccount.create=true \
  --set podSecurityPolicy.enabled=true \
  --set securityContext.runAsNonRoot=true \
  --set securityContext.fsGroup=1001 \
  --set resources.requests.cpu=50m \
  --set resources.requests.memory=64Mi \
  --set resources.limits.cpu=200m \
  --set resources.limits.memory=256Mi \
  --set cainjector.enabled=true \
  --set webhook.enabled=true \
  --wait

echo "✅ Cert-Manager installed successfully"

# Wait for cert-manager to be ready
echo "⏳ Waiting for cert-manager pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n $CERT_MANAGER_NAMESPACE --timeout=300s 2>/dev/null || true
sleep 10

# Step 2: Create Let's Encrypt Issuers
echo "📜 Step 2: Creating Let's Encrypt Issuers..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-staging-key
    solvers:
    - http01:
        ingress:
          class: nginx

---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

echo "✅ Let's Encrypt Issuers created successfully"

# Step 3: Deploy NGINX Ingress Controller
echo "🔌 Step 3: Installing NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace $INGRESS_NAMESPACE \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --wait

echo "✅ NGINX Ingress Controller installed successfully"

# Wait for ingress controller to be ready
echo "⏳ Waiting for NGINX controller to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ingress-nginx -n $INGRESS_NAMESPACE --timeout=300s 2>/dev/null || true
sleep 5

# Step 4: Get Ingress IP
echo "🌐 Step 4: Retrieving Ingress IP..."
INGRESS_IP=$(kubectl get svc -n $INGRESS_NAMESPACE -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "PENDING")

if [ "$INGRESS_IP" = "PENDING" ] || [ -z "$INGRESS_IP" ]; then
    echo "⚠️  Ingress IP is still pending. Please update your DNS records manually."
    echo "   Run: kubectl get svc -n $INGRESS_NAMESPACE"
else
    echo "✅ Ingress IP: $INGRESS_IP"
    echo "📝 Please update your DNS records:"
    echo "   $DOMAIN A $INGRESS_IP"
fi

# Step 5: Deploy BankApp
echo "🏦 Step 5: Deploying BankApp..."
mkdir -p $NAMESPACE
helm upgrade --install bankapp ./helm/bankapp \
  --namespace $NAMESPACE \
  --create-namespace \
  --set ingress.enabled=true \
  --set ingress.ingressClassName=nginx \
  --set "ingress.hosts[0].host=$DOMAIN" \
  --set "ingress.hosts[0].paths[0].path=/" \
  --set "ingress.hosts[0].paths[0].pathType=Prefix" \
  --set "ingress.tls[0].secretName=bankapp-tls" \
  --set "ingress.tls[0].hosts[0]=$DOMAIN" \
  --set certManager.enabled=true \
  --set "certManager.clusterIssuer=$ISSUER" \
  --wait

echo "✅ BankApp deployed successfully"

# Step 6: Monitor Certificate Creation
echo "🔐 Step 6: Monitoring Certificate Creation..."
echo "⏳ Waiting for certificate to be issued (this may take 1-5 minutes)..."

for i in {1..60}; do
    CERT_READY=$(kubectl get certificate bankapp-tls -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
    
    if [ "$CERT_READY" = "True" ]; then
        echo "✅ Certificate issued successfully!"
        kubectl describe certificate bankapp-tls -n $NAMESPACE
        break
    fi
    
    if [ $((i % 10)) -eq 0 ]; then
        echo "⏳ Still waiting... ($i/60 checks)"
        kubectl get certificate bankapp-tls -n $NAMESPACE 2>/dev/null || true
    fi
    
    sleep 5
done

if [ "$CERT_READY" != "True" ]; then
    echo "⚠️  Certificate is still pending. Check logs with:"
    echo "   kubectl logs -n $CERT_MANAGER_NAMESPACE -l app=cert-manager -f"
fi

# Final Summary
echo ""
echo "================================"
echo "🎉 Deployment Complete!"
echo "================================"
echo ""
echo "📊 Status Check:"
echo ""
echo "Cert-Manager: $(kubectl get deployment -n $CERT_MANAGER_NAMESPACE cert-manager -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' 2>/dev/null) ready"
echo "NGINX Ingress: $(kubectl get deployment -n $INGRESS_NAMESPACE -o jsonpath='{.items[0].status.readyReplicas}/{.items[0].spec.replicas}' 2>/dev/null) ready"
echo "BankApp: $(kubectl get deployment -n $NAMESPACE -o jsonpath='{.items[0].status.readyReplicas}/{.items[0].spec.replicas}' 2>/dev/null) ready"
echo ""
echo "🌐 Access your application:"
echo "   https://$DOMAIN"
echo ""
echo "📝 Useful commands:"
echo "   kubectl get certificate -n $NAMESPACE"
echo "   kubectl describe certificate bankapp-tls -n $NAMESPACE"
echo "   kubectl logs -n $CERT_MANAGER_NAMESPACE -l app=cert-manager -f"
echo "   kubectl get ingress -n $NAMESPACE"
echo ""
