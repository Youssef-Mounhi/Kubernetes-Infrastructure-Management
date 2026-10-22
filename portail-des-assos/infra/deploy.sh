#!/bin/bash
set -e

APP_NAME="portail-des-assos"
NAMESPACE="portail-des-assos"
CHART_PATH="/home/mounhiyo/tx-kubernetes-a25/charts/generic-app"
IMAGE="youssef129/portail-des-assos:latest"

echo "Building Docker image $IMAGE..."
docker build -t $IMAGE -f infra/docker/Dockerfile .

echo "Push the Docker image Docker to the registry..."
docker push $IMAGE

echo "📦 Deploying $APP_NAME..."

# Inject .env to infra/helm/values-secret.yaml
bash $CHART_PATH/scripts/inject-env-in-values.sh

# Deploy
echo "Creating manifests"
helm template $APP_NAME $CHART_PATH \
  -f ./infra/helm/values.yaml -f ./infra/helm/values-secret.yaml \
  -n $NAMESPACE > ./infra/k8s/manifests.yaml
echo "Applying manifests..."
kubectl apply -f infra/k8s/manifests.yaml -n $NAMESPACE

echo "✅ Deployed successfully!"
echo ""
kubectl get pods -n $NAMESPACE