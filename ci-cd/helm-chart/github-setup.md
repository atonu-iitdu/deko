# GitHub Repository Setup Commands

## 1. GitHub Repository তৈরি করুন

1. GitHub.com এ যান
2. "New repository" click করুন
3. Repository name দিন (যেমন: `acme-wp-helm`)
4. "Create repository" click করুন

## 2. Local Repository Push করুন

```bash
# Remote repository add করুন (YOUR_USERNAME এবং YOUR_REPO_NAME replace করুন)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# Branch set করুন
git branch -M main

# Push করুন
git push -u origin main
```

## 3. ArgoCD Application Manifest Update করুন

`argocd-application.yaml` ফাইলে line 10 এ আপনার repository URL update করুন:

```yaml
repoURL: https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
```

## 4. Updated Files Push করুন

```bash
# Changes add করুন
git add argocd-application.yaml argocd-installation.md github-setup.md

# Commit করুন
git commit -m "Add ArgoCD deployment configuration"

# Push করুন
git push origin main
```

## 5. ArgoCD Application Deploy করুন

```bash
# ArgoCD Application apply করুন
kubectl apply -f argocd-application.yaml

# Status check করুন
kubectl get applications -n argocd
```

## Example Commands:

```bash
# Example: যদি আপনার repository URL হয়
# https://github.com/johndoe/acme-wp-helm.git

git remote add origin https://github.com/johndoe/acme-wp-helm.git
git branch -M main
git push -u origin main
```
