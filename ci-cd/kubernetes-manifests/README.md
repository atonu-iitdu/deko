# ACME WordPress 3-Tier Application - Kubernetes Manifests

একটি 3-tier WordPress application যা Kubernetes এ HPA, VPA, MetalLB এবং Nginx Ingress সহ deploy করা যায়।

## 🏗️ Architecture

- **Database**: MySQL (`acme-wp-db`)
- **API**: WordPress API (`acme-wp-api`) 
- **Frontend**: WordPress Frontend (`acme-wp-frontend`)

## 📁 File Structure

```
kubernetes-manifests/
├── 01-namespace.yaml          # Namespace
├── 02-database-pvc.yaml       # Database persistent volume
├── 03-database-deployment.yaml # Database deployment
├── 04-database-service.yaml   # Database service
├── 05-api-pvc.yaml           # API persistent volume
├── 06-api-deployment.yaml    # API deployment
├── 07-api-service.yaml       # API service
├── 08-frontend-pvc.yaml      # Frontend persistent volume
├── 09-frontend-deployment.yaml # Frontend deployment
├── 10-frontend-service.yaml  # Frontend service
├── 11-hpa.yaml              # Horizontal Pod Autoscaler
├── 12-vpa.yaml              # Vertical Pod Autoscaler
├── 13-metallb-config.yaml   # MetalLB configuration
├── 14-ingress.yaml          # Ingress configuration
├── install.sh               # Linux/Mac installation script
├── install.ps1              # Windows PowerShell script
└── README.md                # This file
```

## 🚀 Quick Installation

### Option 1: Automated Script (Recommended)

#### Linux/Mac:
```bash
chmod +x install.sh
./install.sh
```

#### Windows PowerShell:
```powershell
.\install.ps1
```

### Option 2: Manual Installation

#### 1. Prerequisites
```bash
# MetalLB install করুন
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Nginx Ingress Controller install করুন
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# VPA install করুন (optional)
kubectl apply -f https://github.com/kubernetes/autoscaler/releases/download/vertical-pod-autoscaler-0.14.0/vpa-release.yaml
```

#### 2. Deploy Application
```bash
# All manifests apply করুন
kubectl apply -f .

# অথবা step by step
kubectl apply -f 01-namespace.yaml
kubectl apply -f 02-database-pvc.yaml
kubectl apply -f 03-database-deployment.yaml
kubectl apply -f 04-database-service.yaml
kubectl apply -f 05-api-pvc.yaml
kubectl apply -f 06-api-deployment.yaml
kubectl apply -f 07-api-service.yaml
kubectl apply -f 08-frontend-pvc.yaml
kubectl apply -f 09-frontend-deployment.yaml
kubectl apply -f 10-frontend-service.yaml
kubectl apply -f 11-hpa.yaml
kubectl apply -f 12-vpa.yaml
kubectl apply -f 13-metallb-config.yaml
kubectl apply -f 14-ingress.yaml
```

## 🌐 Access Application

### External Access
- **URL**: `http://deko.sdlbdcloud.com`
- **DNS**: Make sure `deko.sdlbdcloud.com` points to `192.168.122.210`

### Local Access
```bash
# Frontend access
kubectl port-forward -n acme-wp svc/acme-wp-frontend 8005:80

# API access
kubectl port-forward -n acme-wp svc/acme-wp-api 8080:80

# Database access
kubectl port-forward -n acme-wp svc/acme-wp-db 3306:3306
```

## 📊 Monitoring

### Check Application Status
```bash
# Pods status
kubectl get pods -n acme-wp

# Services status
kubectl get svc -n acme-wp

# Ingress status
kubectl get ingress -n acme-wp

# HPA status
kubectl get hpa -n acme-wp

# VPA status
kubectl get vpa -n acme-wp
```

### View Logs
```bash
# Database logs
kubectl logs -n acme-wp deployment/acme-wp-db

# API logs
kubectl logs -n acme-wp deployment/acme-wp-api

# Frontend logs
kubectl logs -n acme-wp deployment/acme-wp-frontend
```

## 🔧 Configuration

### Database Configuration
- **Root Password**: `rootpassword`
- **Database**: `wordpress`
- **User**: `wordpress`
- **Password**: `wordpress`

### Resource Limits
- **Database**: 500m CPU, 1Gi Memory
- **API**: 500m CPU, 512Mi Memory
- **Frontend**: 500m CPU, 512Mi Memory

### Autoscaling
- **HPA**: 1-10 replicas, 80% CPU/Memory threshold
- **VPA**: Auto mode enabled

## 🛠️ Troubleshooting

### Common Issues

#### 1. Pods Not Starting
```bash
# Check pod events
kubectl describe pod -n acme-wp <pod-name>

# Check pod logs
kubectl logs -n acme-wp <pod-name>
```

#### 2. Database Connection Issues
```bash
# Check database pod
kubectl logs -n acme-wp deployment/acme-wp-db

# Test database connection
kubectl exec -it -n acme-wp deployment/acme-wp-api -- mysql -h acme-wp-db -u wordpress -p
```

#### 3. Ingress Not Working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress status
kubectl describe ingress -n acme-wp acme-wp-ingress
```

#### 4. MetalLB Issues
```bash
# Check MetalLB pods
kubectl get pods -n metallb-system

# Check MetalLB config
kubectl get configmap -n metallb-system config -o yaml
```

## 🗑️ Cleanup

### Uninstall Application
```bash
# Delete all resources
kubectl delete -f .

# অথবা namespace delete করুন
kubectl delete namespace acme-wp
```

### Uninstall Prerequisites
```bash
# MetalLB uninstall
kubectl delete namespace metallb-system

# Nginx Ingress uninstall
kubectl delete namespace ingress-nginx

# VPA uninstall
kubectl delete -f https://github.com/kubernetes/autoscaler/releases/download/vertical-pod-autoscaler-0.14.0/vpa-release.yaml
```

## 📋 Features

✅ **3-Tier Architecture** - Database, API, Frontend  
✅ **HPA** - Horizontal Pod Autoscaler  
✅ **VPA** - Vertical Pod Autoscaler  
✅ **MetalLB** - LoadBalancer service  
✅ **Nginx Ingress** - External access  
✅ **Persistent Storage** - All tiers have persistent volumes  
✅ **Health Checks** - Liveness এবং readiness probes  
✅ **Resource Management** - CPU/Memory limits এবং requests  
✅ **Automated Installation** - One-click deployment scripts  

## 🔒 Security Notes

- Change default database passwords in production
- Enable TLS for ingress in production
- Implement network policies for better security
- Use proper RBAC permissions

## 📞 Support

এই manifests সম্পর্কে কোনো প্রশ্ন থাকলে GitHub repository তে issue create করুন।
