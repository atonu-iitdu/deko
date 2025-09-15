# ACME WordPress 3-Tier Application

একটি 3-tier WordPress application যা Kubernetes এ HPA, VPA, MetalLB এবং Nginx Ingress সহ deploy করা যায়।

## Architecture

- **Database**: MySQL (`acme-wp-db`)
- **API**: WordPress API (`acme-wp-api`) 
- **Frontend**: WordPress Frontend (`acme-wp-frontend`)

## Prerequisites

```bash
# MetalLB install করুন
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Nginx Ingress Controller install করুন
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

## Installation

```bash
# Namespace তৈরি করুন
kubectl create namespace acme-wp

# Application deploy করুন
helm install acme-wp . -n acme-wp
```

## Access

- **External**: `http://deko.sdlbdcloud.com`
- **Local**: `kubectl port-forward -n acme-wp svc/acme-wp-frontend 8005:80`

## Features

✅ HPA (Horizontal Pod Autoscaler)  
✅ VPA (Vertical Pod Autoscaler)  
✅ MetalLB LoadBalancer  
✅ Nginx Ingress  
✅ Persistent Storage  

## Uninstall

```bash
helm uninstall acme-wp -n acme-wp
```
