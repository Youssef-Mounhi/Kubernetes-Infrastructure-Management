#!/bin/bash
set -e

APP_NAME="site-vitrine-simde"
NAMESPACE="site-vitrine-simde"
CHART_PATH="/home/mounhiyo/tx-kubernetes-a25/charts/generic-app"
IMAGE="youssef129/site-vitrine-simde:latest"

echo "Building Docker image $IMAGE..."
docker build -t $IMAGE -f infra/docker/Dockerfile .

echo "Push the Docker image Docker to the registry..."
docker push $IMAGE

echo "📦 Deploying $APP_NAME..."

# Deploy
echo "Creating manifests"
helm template $APP_NAME $CHART_PATH \
  -f ./infra/helm/values.yaml\
  -n $NAMESPACE > ./infra/k8s/manifests.yaml
echo "Applying manifests..."
kubectl apply -f infra/k8s/manifests.yaml -n $NAMESPACE

echo "✅ Deployed successfully!"
echo ""
kubectl get pods -n $NAMESPACE