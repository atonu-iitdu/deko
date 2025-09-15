# ArgoCD Installation এবং Deployment Guide

## 1. ArgoCD Installation

### Kubernetes Cluster এ ArgoCD Install করুন:

```bash
# ArgoCD namespace তৈরি করুন
kubectl create namespace argocd

# ArgoCD install করুন
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ArgoCD server pod ready হওয়ার জন্য অপেক্ষা করুন
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### ArgoCD Admin Password পাওয়ার জন্য:

```bash
# Initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

### ArgoCD UI Access:

```bash
# Port forward করুন
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Browser এ যান: https://localhost:8080
# Username: admin
# Password: উপরের command থেকে পাওয়া password
```

## 2. GitHub Repository Setup

### GitHub এ Repository তৈরি করুন:

1. GitHub এ নতুন repository তৈরি করুন
2. Repository URL note করুন (যেমন: `https://github.com/username/repo-name.git`)

### Local Repository Push করুন:

```bash
# Remote repository add করুন
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# Branch set করুন
git branch -M main

# Push করুন
git push -u origin main
```

## 3. ArgoCD Application Deploy

### ArgoCD Application Manifest Update করুন:

`argocd-application.yaml` ফাইলে আপনার GitHub repository URL update করুন:

```yaml
source:
  repoURL: https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git  # এখানে আপনার repo URL দিন
```

### Application Deploy করুন:

```bash
# ArgoCD Application apply করুন
kubectl apply -f argocd-application.yaml

# Application status check করুন
kubectl get applications -n argocd

# Application details দেখুন
kubectl describe application acme-wp -n argocd
```

## 4. ArgoCD CLI Installation (Optional)

```bash
# ArgoCD CLI install করুন
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# ArgoCD login করুন
argocd login localhost:8080

# Application sync করুন
argocd app sync acme-wp
```

## 5. Application Access

### ArgoCD UI থেকে:
1. ArgoCD UI এ যান
2. `acme-wp` application select করুন
3. Application status এবং logs দেখুন

### Application Access:
- **External**: `http://deko.sdlbdcloud.com`
- **Local**: `kubectl port-forward -n acme-wp svc/acme-wp-frontend 8005:80`

## 6. Troubleshooting

### Application Sync Issues:
```bash
# Application status check
kubectl get applications -n argocd

# Application events
kubectl describe application acme-wp -n argocd

# Manual sync
argocd app sync acme-wp --force
```

### Pod Issues:
```bash
# Pod status
kubectl get pods -n acme-wp

# Pod logs
kubectl logs -n acme-wp <pod-name>

# Pod describe
kubectl describe pod -n acme-wp <pod-name>
```

## 7. Cleanup

```bash
# ArgoCD Application delete
kubectl delete application acme-wp -n argocd

# ArgoCD uninstall
kubectl delete namespace argocd
```
