# Let's Encrypt & Gateway API Setup Guide

This guide covers the installation and configuration of cert-manager (for Let's Encrypt SSL/TLS certificates) and Kubernetes Gateway API packages for the bankapp Helm deployment.

---

## Table of Contents

1. [Cert-Manager Installation](#cert-manager-installation)
2. [Let's Encrypt Configuration](#lets-encrypt-configuration)
3. [Gateway API Installation](#gateway-api-installation)
4. [Complete Deployment Workflow](#complete-deployment-workflow)
5. [Troubleshooting](#troubleshooting)

---

## Cert-Manager Installation

### Prerequisites

- Kubernetes cluster v1.21 or higher
- kubectl configured to access your cluster
- Helm 3.x installed
- Appropriate RBAC permissions

### Step 1: Add Jetstack Helm Repository

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

### Step 2: Install cert-manager via Helm

```bash
# Create namespace for cert-manager
kubectl create namespace cert-manager

# Install cert-manager with CRDs and recommended security settings
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.13.0 \
  --set installCRDs=true \
  --set global.leaderElection.namespace=cert-manager \
  --set serviceAccount.create=true \
  --set podSecurityPolicy.enabled=true \
  --set securityContext.runAsNonRoot=true \
  --set securityContext.fsGroup=1001 \
  --set resources.requests.cpu=50m \
  --set resources.requests.memory=64Mi \
  --set resources.limits.cpu=200m \
  --set resources.limits.memory=256Mi \
  --set cainjector.enabled=true \
  --set cainjector.replicaCount=1 \
  --set webhook.enabled=true \
  --set webhook.replicaCount=1 \
  --set webhook.securePort=10250 \
  --wait
```

### Step 3: Verify Installation

```bash
# Check if cert-manager pods are running
kubectl get pods --namespace cert-manager

# Expected output should show:
# cert-manager-xxx
# cert-manager-cainjector-xxx
# cert-manager-webhook-xxx
```

---

## Let's Encrypt Configuration

### Step 1: Create Let's Encrypt Cluster Issuers

Create a file named `letsencrypt-issuers.yaml`:

```yaml
# Let's Encrypt Staging Issuer (for testing)
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@bankapp.example.com  # Change this to your email
    privateKeySecretRef:
      name: letsencrypt-staging-key
    solvers:
    - http01:
        ingress:
          class: nginx

---
# Let's Encrypt Production Issuer (for live certificates)
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@bankapp.example.com  # Change this to your email
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

### Step 2: Apply the Issuers

```bash
kubectl apply -f letsencrypt-issuers.yaml
```

### Step 3: Verify Cluster Issuers

```bash
# List cluster issuers
kubectl get clusterissuers

# Describe a specific issuer to check status
kubectl describe clusterissuer letsencrypt-staging
kubectl describe clusterissuer letsencrypt-prod
```

---

## Gateway API Installation

### What is Kubernetes Gateway API?

The Gateway API is a collection of resources for advanced load balancing, service mesh integration, and routing policies. It provides a more expressive alternative to Ingress.

### Step 1: Install Gateway API CRDs

```bash
# Install the latest Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# For experimental features (optional)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/experimental-install.yaml
```

### Step 2: Verify Gateway API Installation

```bash
# Check if Gateway API CRDs are installed
kubectl get crds | grep gateway.networking.k8s.io

# Expected output should include:
# gateways.gateway.networking.k8s.io
# gatewayClasses.gateway.networking.k8s.io
# httproutes.gateway.networking.k8s.io
# grpcroutes.gateway.networking.k8s.io
```

### Step 3: Install NGINX Gateway Implementation via Helm

```bash
# Add NGINX helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress Controller with Gateway API support
helm install nginx-gateway ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.gatewayAPI.enable=true \
  --wait
```

### Step 4: Verify NGINX Gateway Controller

```bash
# Check if NGINX gateway controller pods are running
kubectl get pods -n ingress-nginx

# Verify gateway class is available
kubectl get gatewayclass
```

---

## Complete Deployment Workflow

### Step 1: Deploy Cert-Manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true \
  --set global.leaderElection.namespace=cert-manager \
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
```

### Step 2: Create Let's Encrypt Issuers

```bash
kubectl apply -f letsencrypt-issuers.yaml
```

### Step 3: Deploy NGINX Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

### Step 4: Deploy Bankapp with Helm

```bash
# Update DNS records to point to your ingress LoadBalancer IP
INGRESS_IP=$(kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Point bankapp.example.com to: $INGRESS_IP"

# Deploy bankapp with TLS enabled
helm install bankapp ./helm/bankapp \
  --namespace bankapp \
  --create-namespace \
  --set ingress.enabled=true \
  --set ingress.ingressClassName=nginx \
  --set ingress.hosts[0].host=bankapp.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix \
  --set ingress.tls[0].secretName=bankapp-tls \
  --set ingress.tls[0].hosts[0]=bankapp.example.com \
  --set certManager.enabled=true \
  --set certManager.clusterIssuer=letsencrypt-prod
```

**Alternative: Deploy with staging issuer first for testing**

```bash
helm install bankapp ./helm/bankapp \
  --namespace bankapp \
  --create-namespace \
  --set ingress.enabled=true \
  --set ingress.ingressClassName=nginx \
  --set ingress.hosts[0].host=bankapp.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix \
  --set ingress.tls[0].secretName=bankapp-tls \
  --set ingress.tls[0].hosts[0]=bankapp.example.com \
  --set certManager.enabled=true \
  --set certManager.clusterIssuer=letsencrypt-staging
```

### Step 5: Monitor Certificate Creation

```bash
# Check certificate status
kubectl get certificates -n bankapp

# Check certificate details
kubectl describe certificate bankapp-tls -n bankapp

# Check cert-manager logs for any issues
kubectl logs -n cert-manager -l app=cert-manager -f
```

---

## Troubleshooting

### Certificate Not Being Issued

```bash
# 1. Check ClusterIssuer status
kubectl describe clusterissuer letsencrypt-prod

# 2. Check Certificate CRD status
kubectl describe certificate bankapp-tls -n bankapp

# 3. Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# 4. Check ACME challenges
kubectl get challenges -n bankapp
kubectl describe challenge <challenge-name> -n bankapp
```

### Common Issues & Solutions

#### Issue: "Waiting for HTTP-01 self check propagation"

**Solution:** Ensure your ingress is properly configured and DNS is pointing to the correct IP:

```bash
# Get ingress IP
kubectl get ingress -n bankapp -o wide

# Verify DNS resolution
nslookup bankapp.example.com
```

#### Issue: "Certificate secret not created"

**Solution:** Check the Let's Encrypt issuer's email and rate limits:

```bash
# Use staging issuer first for testing
kubectl patch certificate bankapp-tls -n bankapp \
  -p '{"spec":{"issuerRef":{"name":"letsencrypt-staging"}}}'
```

#### Issue: "IngressClass not found"

**Solution:** Ensure ingress controller is installed:

```bash
kubectl get ingressclass
# Should show 'nginx' class

# If not, reinstall:
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

### Useful Debugging Commands

```bash
# Check all cert-manager related resources
kubectl get clusterissuer,issuer,certificate,certificaterequest,order,challenge -A

# Test HTTP-01 challenge manually
kubectl run test-pod --image=nginx -n bankapp
kubectl port-forward pod/test-pod 8080:80 -n bankapp

# Check Let's Encrypt rate limits
curl https://crt.sh/api/v1/log/entries?serial=<certificate-serial> | jq

# Validate certificate
openssl s_client -connect bankapp.example.com:443 -showcerts
```

---

## Security Best Practices

1. **Always test with staging issuer first** to avoid rate limiting
2. **Rotate certificates regularly** (cert-manager does this automatically)
3. **Use network policies** to restrict traffic to cert-manager
4. **Enable Pod Security Policies** for cert-manager components
5. **Monitor certificate expiration** with alerts
6. **Keep cert-manager updated** to get security patches

---

## References

- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

---

## Support

For issues and questions:
- Check cert-manager logs: `kubectl logs -n cert-manager -l app=cert-manager`
- Consult official documentation links above
- Review Kubernetes events: `kubectl describe` commands
