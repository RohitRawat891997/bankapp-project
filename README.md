# 🚀 ArgoCD Installation & Setup on Kubernetes

This guide explains how to install and configure **ArgoCD** on a Kubernetes cluster using **Helm**.

---

# Prerequisites

- Kubernetes Cluster
- kubectl configured
- Helm installed

Verify:

```bash
kubectl version
helm version
```

---

# Step 1: Add the ArgoCD Helm Repository

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

---

# Step 2: Create the ArgoCD Namespace

```bash
kubectl create namespace argocd
```

---

# Step 3: Install ArgoCD

```bash
helm install argocd argo/argo-cd -n argocd
```

---

# Step 4: Verify Installation

Watch all ArgoCD resources until they become **Running**.

```bash
watch kubectl get all -n argocd
```

Expected output:

- argocd-server
- argocd-repo-server
- argocd-application-controller
- argocd-dex-server
- argocd-redis
- argocd-applicationset-controller
- argocd-notifications-controller

All pods should be in the **Running** state.

---

# Step 5: Configure ArgoCD to Run Without TLS (HTTP)

Patch the ArgoCD ConfigMap:

```bash
kubectl patch configmap argocd-cmd-params-cm -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'
```

Restart the ArgoCD server:

```bash
kubectl rollout restart deployment argocd-server -n argocd
```

---

# Step 6: Access the ArgoCD UI

## Option 1 (Recommended): Port Forward

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address=0.0.0.0
```

Open:

```
http://<SERVER-IP>:8080
```

---

## Option 2: Expose ArgoCD Using NodePort

If port-forwarding doesn't work, edit the service.

```bash
kubectl edit service argocd-server -n argocd
```

Change the Service type:

```yaml
spec:
  type: NodePort
```

Add a NodePort under the HTTPS port:

```yaml
ports:
- name: https
  port: 443
  targetPort: 8080
  nodePort: 30002
```

Save the file.

Verify:

```bash
kubectl get svc -n argocd
```

Example:

```
NAME             TYPE       PORT(S)
argocd-server    NodePort   443:30002/TCP
```

Now access ArgoCD:

```
http://<NODE-IP>:30002
```

or

```
http://<PUBLIC-IP>:30002
```

> **Note:** Replace `<NODE-IP>` or `<PUBLIC-IP>` with your Kubernetes node's IP address.

---

# Step 7: Get the Initial Admin Password

Run:

```bash
kubectl get secret argocd-initial-admin-secret \
-n argocd \
-o jsonpath="{.data.password}" | base64 -d && echo
```

Example output:

```
q2XbP7LmA8vY
```

---

# Step 8: Login to ArgoCD

Username:

```
admin
```

Password:

```
<password obtained in the previous step>
```

---

# Verify Installation

Check all resources:

```bash
kubectl get all -n argocd
```

Expected:

```
Pods:
✓ argocd-server
✓ argocd-repo-server
✓ argocd-redis
✓ argocd-dex-server
✓ argocd-application-controller
✓ argocd-applicationset-controller
✓ argocd-notifications-controller

Service:
✓ argocd-server (NodePort or ClusterIP)

Deployments:
✓ All Available

StatefulSets:
✓ argocd-application-controller
```

---

# Useful Commands

## Check Pods

```bash
kubectl get pods -n argocd
```

## Check Services

```bash
kubectl get svc -n argocd
```

## Check Deployments

```bash
kubectl get deployments -n argocd
```

## Restart ArgoCD Server

```bash
kubectl rollout restart deployment argocd-server -n argocd
```

## Uninstall ArgoCD

```bash
helm uninstall argocd -n argocd
kubectl delete namespace argocd
```

---

# Architecture

```
                Git Repository
                       │
                       │
                 ArgoCD Repo Server
                       │
                       ▼
              Application Controller
                       │
                       ▼
               Kubernetes Cluster
                       │
        ┌──────────────┴──────────────┐
        │                             │
   Deployments                  StatefulSets
        │                             │
        └──────────────┬──────────────┘
                       ▼
                  Running Applications
```

---
<img width="1600" height="1022" alt="WhatsApp Image 2026-06-27 at 17 54 25" src="https://github.com/user-attachments/assets/5ee6a8f8-e8c0-44b2-8ef8-2b03ac52849f" />
<img width="1600" height="1024" alt="WhatsApp Image 2026-06-27 at 17 55 00" src="https://github.com/user-attachments/assets/777fbdaa-2db0-4073-a553-25f5785f895a" />
<img width="1600" height="969" alt="WhatsApp Image 2026-06-27 at 17 56 55" src="https://github.com/user-attachments/assets/1f9d855a-a164-4bb6-8785-3402beb3b25f" />
<img width="1600" height="1008" alt="WhatsApp Image 2026-06-27 at 17 58 32" src="https://github.com/user-attachments/assets/59fa76da-ba68-4a9a-8f82-3ba579413619" />




# Congratulations! 🎉

ArgoCD is now installed and ready to deploy applications using the GitOps workflow.
