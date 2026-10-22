# Deployment

## Prerequisites

- kubectl configured for k3s cluster
- Helm 3 installed (for templating only)
- Helm chart `generic-app` cloned

## Deploy
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

**Important : ** 
This deploys a redis container as well for the portail-des-assos app, but it is recommended to use an external redis service.

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