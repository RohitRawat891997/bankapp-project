This folder contains raw Kubernetes manifests for quick testing and debugging. For production-ready deployments please use the Helm chart in helm/bankapp which is parameterized and documented in docs/

Files in k8s-manifests/
- bankapp-deploy.yaml  - The Deployment + NetworkPolicy used for development/testing. The Helm chart templates this manifest and extends it with probes, templates and better defaults.

Why keep raw manifests?
- Quick debugging when you need to apply a single file with kubectl.
- The manifest is a reference of the concrete runtime objects used in development.

Use the Helm chart for day-to-day deployments and CI/CD automation:
helm install bankapp ./helm/bankapp -n bankapp --create-namespace

