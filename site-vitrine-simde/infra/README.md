# Deployment

## Prerequisites

- kubectl configured for k3s cluster
- Helm 3 installed (for templating only)
- Helm chart `generic-app` cloned

## Deploy
Il est important d'avoir dans index.html : 
```html
<base href="/simde/">
```
Ensuite : 
```bash
# from root of project
bash infra/deploy.sh
```

This will:
1. Fetch/update the generic-app Helm chart
2. Render templates with your values.yaml
3. Apply manifests to the cluster

## Configuration

Edit `values.yaml` to configure:
- Docker image and tag
- Resource limits
- Ingress hostname
- Environment variables
- Storage volumes

## Update deployment
```bash
# Edit values.yaml

# Re-deploy
bash infra/deploy.sh
```

## Remove deployment
```bash
kubectl delete -f infra/k8s/manifests.yaml
```