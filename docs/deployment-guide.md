# Production deployment guide for BankApp

This guide explains how to deploy the BankApp Helm chart in a production-ready way.

Prerequisites
- Kubernetes cluster (1.21+ recommended)
- Helm 3.8+
- Ingress controller (NGINX, Traefik, or another supported by cert-manager)
- cert-manager installed (for TLS)
- A domain name and DNS pointing to the ingress

Quick start
1. Clone the repo and switch to the branch:

   git fetch origin k8s-helm-production
   git checkout k8s-helm-production

2. Create the target namespace:

   kubectl create namespace bankapp

3. Configure mandatory secrets (do NOT store production secrets in values.yaml).
   Example:

   kubectl create secret generic mysql-secret \
     --from-literal=MYSQL_DATABASE=bankappdb \
     --from-literal=MYSQL_USER=bankapp \
     --from-literal=MYSQL_PASSWORD='<strong-password>' \
     -n bankapp

4. (Optional) Edit helm/bankapp/values.yaml to set your domain under ingress.hosts[0].host and switch certManager.clusterIssuer to letsencrypt-prod when ready.

5. Install the chart:

   helm install bankapp ./helm/bankapp -n bankapp --create-namespace

6. Verify deployment:

   kubectl get pods -n bankapp
   kubectl get svc -n bankapp
   kubectl get ingress -n bankapp

Production recommendations
- Start with letsencrypt-staging (rate limits) and only switch to letsencrypt-prod after validation.
- Use sealed-secrets or ExternalSecrets to store production DB credentials and other sensitive data.
- Enable HPA when metrics server is available and tune resource requests/limits.
- Integrate Prometheus/Grafana for metrics and alerts.
- Add readiness and liveness endpoints to the application for better lifecycle handling.

Security
- Keep automountServiceAccountToken: false (already set)
- Use PodSecurity admission policies to enforce non-root containers and restrict capabilities.
- Lock down network access using the provided NetworkPolicy and add egress restrictions if needed.

Rolling updates and canary
- Use helm upgrade to perform rolling updates.
- Consider using a service mesh (e.g., Istio, Linkerd) or progressive delivery tooling (Argo Rollouts, Flagger) for canary deployments.

