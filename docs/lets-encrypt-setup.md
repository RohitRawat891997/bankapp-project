# Let's Encrypt & cert-manager setup

This document shows how to install cert-manager and create ClusterIssuers for Let's Encrypt (staging and production).

1. Install cert-manager (recommended: manifests from cert-manager release):

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

2. Create a staging ClusterIssuer (use this to test without hitting production rate limits):

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
      - http01:
          ingress:
            class: nginx
```

Apply:

kubectl apply -f - <<EOF
[PASTE YAML ABOVE]
EOF

3. Create a production ClusterIssuer (only after testing with staging):

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

Apply as above.

4. DNS / HTTP-01
- Ensure your DNS record for bankapp.example.com points to your ingress controller's external IP/LoadBalancer.
- cert-manager will create a temporary challenge ingress to complete HTTP-01 validation.

5. Troubleshooting
- Check cert-manager logs: kubectl logs deploy/cert-manager -n cert-manager
- Describe Certificate and Order resources to see ACME challenge status:
  kubectl describe certificate <name> -n bankapp
  kubectl describe order -n cert-manager

6. Notes on other ingress controllers
- For Traefik, Contour or others, set the appropriate ingress class in the solver stanza and in the ingress annotations.

