Deploying the hello-world-http Example on Kubernetes

This guide explains how to deploy the Hello World HTTP image
 to a Kubernetes cluster (tested on Ubuntu + k3s) using YAML manifests.

# Prerequisites

Before deploying, make sure you have:

An Ubuntu machine (physical, VM, or cloud)

curl, git, and vim installed

`sudo apt update && sudo apt install -y curl git vim`

A working Kubernetes cluster (for example, k3s)

`curl -sfL https://get.k3s.io | sh -`


k3s automatically installs Traefik as the default Ingress controller.

kubectl configured and working
```
sudo k3s kubectl get nodes
// Or set an alias for convenience
alias kubectl='sudo k3s kubectl'
```

# Configuration Overview

Image: `ghcr.io/kljensen/hello-world-http:latest`

Container Port: `8000`

Environment Variables:

`HOST=0.0.0.0`
`PORT=8000`

Service Port:  `80 → 8000`

Ingress Host: `hello.local` (change if needed)

# Step 1 — Create Kubernetes Namespace

Create a namespace to isolate the app (optional but recommended):

`kubectl apply -f k8s/namespace.yaml`

# Step 2 — Deploy the Application

Deploy the Pod replicas:

`kubectl -n hello apply -f k8s/deployment.yaml`

Verify:

`kubectl -n hello get pods -o wide`

# Step 3 — Expose with a Service

Expose the Deployment internally in the cluster:

`kubectl -n hello apply -f k8s/service.yaml`


Check:

`kubectl -n hello get svc`


You should see something like:
```
NAME              TYPE        CLUSTER-IP      PORT(S)   AGE
hello-http-svc    ClusterIP   10.43.112.21    80/TCP    1m
```

# Step 4 — Configure Ingress (HTTP Access)

Apply the Ingress resource to route HTTP traffic to your Service:

`kubectl -n hello apply -f k8s/ingress.yaml`


Confirm that the Ingress is active:

`kubectl -n hello get ingress`


Example output:
```
NAME             CLASS     HOSTS               ADDRESS         PORTS   AGE
hello-http-ing   traefik   hello.localtest.me  192.168.56.10   80      1m
```

# Step 5 — Local DNS / Hosts Setup

Find your cluster or node IP (for k3s, it’s usually your VM’s IP):

`ip -br a`


Edit your /etc/hosts file and add:

`192.168.56.10   hello.local`

# Step 6 — Test the Application

Now open a browser or run:

`curl -H "Host: hello.local" http://192.168.56.10/`


Expected output:

`Hello, World!`

# Step 7 — Clean Up

To remove all deployed resources:
```
kubectl -n hello delete -f k8s/ingress.yaml
kubectl -n hello delete -f k8s/service.yaml
kubectl -n hello delete -f k8s/deployment.yaml
kubectl delete ns hello