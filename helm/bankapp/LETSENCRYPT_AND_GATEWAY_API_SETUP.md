# Let's Encrypt & Gateway API Setup Guide

This guide covers the installation and configuration of cert-manager (for Let's Encrypt SSL/TLS certificates) and Kubernetes Gateway API packages for the bankapp Helm deployment.

---

## Table of Contents

1. [Cert-Manager Installation](#cert-manager-installation)
2. [Let's Encrypt Configuration](#lets-encrypt-configuration)
3. [Gateway API Installation](#gateway-api-installation)
4. [Integration with Bankapp Helm Chart](#integration-with-bankapp-helm-chart)
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

### Step 2: Install cert-manager

```bash
# Create namespace for cert-manager
kubectl create namespace cert-manager

# Install cert-manager with CRDs
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.13.0 \
  --set installCRDs=true \
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

### Helm Values for Cert-Manager (Optional Enhancement)

If you need custom configuration, create a `cert-manager-values.yaml`:

```yaml
global:
  leaderElection:
    namespace: cert-manager

cert-manager:
  enabled: true
  installCRDs: true
  
  serviceAccount:
    create: true
    name: cert-manager
  
  podSecurityPolicy:
    enabled: true
  
  securityContext:
    runAsNonRoot: true
    fsGroup: 1001
  
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 256Mi

cainjector:
  enabled: true
  replicaCount: 1

webhook:
  enabled: true
  replicaCount: 1
  securePort: 10250
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

### Step 4: Update Bankapp values.yaml

Update the cert-manager configuration in your `helm/bankapp/values.yaml`:

```yaml
certManager:
  enabled: true
  clusterIssuer: letsencrypt-prod  # Use letsencrypt-staging for testing first
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

### Step 3: Install a Gateway Implementation (NGINX)

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

### Step 4: Create a Gateway Class

Create a file named `gateway-class.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx
spec:
  controllerName: k8s.io/ingress-nginx
```

Apply it:

```bash
kubectl apply -f gateway-class.yaml
```

---

## Integration with Bankapp Helm Chart

### Option 1: Using Traditional Ingress (Recommended for Simple Setup)

Your current `values.yaml` already uses Ingress. Ensure these settings are in place:

```yaml
ingress:
  enabled: true
  ingressClassName: nginx
  hosts:
    - host: bankapp.example.com
      paths:
        - /
  tls:
    - secretName: bankapp-tls
      hosts:
        - bankapp.example.com

certManager:
  enabled: true
  clusterIssuer: letsencrypt-prod
```

### Option 2: Using Gateway API (Advanced)

Create a new file `helm/bankapp/templates/gateway.yaml`:

```yaml
{{- if .Values.gatewayAPI.enabled }}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: {{ include "bankapp.fullname" . }}-gateway
  namespace: {{ .Release.Namespace }}
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    routes:
      group: gateway.networking.k8s.io
      kind: HTTPRoute
      selector:
        matchLabels:
          gateway: {{ include "bankapp.fullname" . }}
  - name: https
    port: 443
    protocol: HTTPS
    tls:
      certificateRefs:
      - name: {{ .Values.gatewayAPI.tlsSecretName | default "bankapp-tls" }}
    routes:
      group: gateway.networking.k8s.io
      kind: HTTPRoute
      selector:
        matchLabels:
          gateway: {{ include "bankapp.fullname" . }}

---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ include "bankapp.fullname" . }}-route
  namespace: {{ .Release.Namespace }}
  labels:
    gateway: {{ include "bankapp.fullname" . }}
spec:
  parentRefs:
  - name: {{ include "bankapp.fullname" . }}-gateway
    namespace: {{ .Release.Namespace }}
  hostnames:
  {{- range .Values.gatewayAPI.hosts }}
  - {{ . }}
  {{- end }}
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: {{ include "bankapp.fullname" . }}
      port: {{ .Values.service.port }}
{{- end }}
```

Add to `values.yaml`:

```yaml
# Gateway API Configuration (optional, for advanced routing)
gatewayAPI:
  enabled: false  # Set to true to use Gateway API instead of Ingress
  hosts:
    - bankapp.example.com
  tlsSecretName: bankapp-tls
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
  --set installCRDs=true \
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

# Deploy bankapp
helm install bankapp ./helm/bankapp \
  -n bankapp \
  --create-namespace \
  -f helm/bankapp/values.yaml
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
