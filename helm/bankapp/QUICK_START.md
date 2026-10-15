# BankApp Let's Encrypt & Gateway API Setup - Quick Reference

## Prerequisites
- Kubernetes cluster v1.21+
- kubectl configured
- Helm 3.x installed
- Domain name for your application

## Quick Start (Automated)

```bash
# Make deployment script executable
chmod +x helm/bankapp/deploy-bankapp.sh

# Run the deployment script
./helm/bankapp/deploy-bankapp.sh bankapp.example.com admin@example.com staging

# Or use production issuers
./helm/bankapp/deploy-bankapp.sh bankapp.example.com admin@example.com prod
```

## Manual Deployment Steps

### 1. Install Cert-Manager
```bash
helm repo add jetstack https://charts.jetstack.io && helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true \
  --set global.leaderElection.namespace=cert-manager \
  --set podSecurityPolicy.enabled=true \
  --wait
```

### 2. Create Let's Encrypt Issuers
```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: your-email@example.com
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
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### 3. Install NGINX Ingress Controller
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && helm repo update

helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer
```

### 4. Deploy BankApp with TLS
```bash
# Get the Ingress IP
kubectl get svc -n ingress-nginx

# Deploy BankApp
helm install bankapp ./helm/bankapp \
  --namespace bankapp --create-namespace \
  --set ingress.hosts[0].host=bankapp.example.com \
  --set ingress.tls[0].hosts[0]=bankapp.example.com \
  --set certManager.clusterIssuer=letsencrypt-staging
```

## Monitoring & Verification

```bash
# Check certificate status
kubectl get certificates -n bankapp
kubectl describe certificate bankapp-tls -n bankapp

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f

# Check ingress status
kubectl get ingress -n bankapp -o wide

# Check ACME challenges
kubectl get challenges -n bankapp
```

## Troubleshooting

### Certificate pending?
```bash
# Check issuer status
kubectl describe clusterissuer letsencrypt-staging

# Check DNS resolution
nslookup bankapp.example.com

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

### Switching from staging to production
```bash
# Update the certificate
kubectl patch certificate bankapp-tls -n bankapp \
  -p '{"spec":{"issuerRef":{"name":"letsencrypt-prod"}}}'

# Or re-deploy with production issuer
helm upgrade bankapp ./helm/bankapp \
  -n bankapp \
  --set certManager.clusterIssuer=letsencrypt-prod
```

## Important Notes

1. **Always test with staging first** to avoid Let's Encrypt rate limits
2. **DNS must be properly configured** before deploying - cert-manager needs to validate domain ownership
3. **Wait for LoadBalancer IP** - cloud providers may take time to assign an external IP
4. **Certificate issuance takes time** - typically 1-5 minutes, depending on DNS propagation

## File Structure

```
helm/bankapp/
├── Chart.yaml                          # Helm chart metadata
├── values.yaml                         # Default configuration values
├── LETSENCRYPT_AND_GATEWAY_API_SETUP.md # Detailed setup guide
├── QUICK_START.md                      # This file
├── deploy-bankapp.sh                   # Automated deployment script
├── templates/
│   ├── ingress.yaml                    # Ingress with cert-manager annotations
│   ├── deployment.yaml                 # Application deployment
│   ├── service.yaml                    # Service definition
│   ├── configmap.yaml                  # Configuration
│   ├── secret.yaml                     # Secrets
│   ├── networkpolicy.yaml              # Network policies
│   ├── hpa.yaml                        # Horizontal pod autoscaler
│   ├── _helpers.tpl                    # Template helpers
└── └── NOTES.txt                       # Post-install notes
```

## Support

For detailed documentation, see:
- [LETSENCRYPT_AND_GATEWAY_API_SETUP.md](./LETSENCRYPT_AND_GATEWAY_API_SETUP.md)
- [cert-manager Docs](https://cert-manager.io/docs/)
- [Let's Encrypt Docs](https://letsencrypt.org/docs/)
