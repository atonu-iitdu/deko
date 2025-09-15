#!/bin/bash

# ACME WordPress 3-Tier Application Installation Script
# This script installs all required components and the application

set -e

echo "🚀 Starting ACME WordPress 3-Tier Application Installation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_success "Kubernetes cluster is accessible"

# Install MetalLB
print_status "Installing MetalLB..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Wait for MetalLB to be ready
print_status "Waiting for MetalLB to be ready..."
kubectl wait --namespace metallb-system \
    --for=condition=ready pod \
    --selector=app=metallb \
    --timeout=300s

print_success "MetalLB installed successfully"

# Install Nginx Ingress Controller
print_status "Installing Nginx Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Wait for Nginx Ingress to be ready
print_status "Waiting for Nginx Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s

print_success "Nginx Ingress Controller installed successfully"

# Install VPA (Optional)
print_status "Installing VPA (Vertical Pod Autoscaler)..."
kubectl apply -f https://github.com/kubernetes/autoscaler/releases/download/vertical-pod-autoscaler-0.14.0/vpa-release.yaml

print_success "VPA installed successfully"

# Deploy the application
print_status "Deploying ACME WordPress Application..."

# Apply all manifests in order
for manifest in *.yaml; do
    if [[ "$manifest" != "install.sh" ]]; then
        print_status "Applying $manifest..."
        kubectl apply -f "$manifest"
    fi
done

print_success "All manifests applied successfully"

# Wait for pods to be ready
print_status "Waiting for application pods to be ready..."
kubectl wait --namespace acme-wp \
    --for=condition=ready pod \
    --selector=app=acme-wp \
    --timeout=600s

print_success "Application pods are ready"

# Get application status
print_status "Application Status:"
echo ""
kubectl get pods -n acme-wp
echo ""
kubectl get svc -n acme-wp
echo ""
kubectl get ingress -n acme-wp

# Get ArgoCD admin password if ArgoCD is installed
if kubectl get namespace argocd &> /dev/null; then
    print_status "ArgoCD is installed. Getting admin password..."
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "ArgoCD password not found")
    if [[ "$ARGOCD_PASSWORD" != "ArgoCD password not found" ]]; then
        print_success "ArgoCD Admin Password: $ARGOCD_PASSWORD"
        print_status "Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    fi
fi

echo ""
print_success "🎉 Installation completed successfully!"
echo ""
print_status "Application Access:"
print_status "  External: http://deko.sdlbdcloud.com"
print_status "  Local: kubectl port-forward -n acme-wp svc/acme-wp-frontend 8005:80"
echo ""
print_status "Useful Commands:"
print_status "  Check pods: kubectl get pods -n acme-wp"
print_status "  Check services: kubectl get svc -n acme-wp"
print_status "  Check ingress: kubectl get ingress -n acme-wp"
print_status "  Check HPA: kubectl get hpa -n acme-wp"
print_status "  Check VPA: kubectl get vpa -n acme-wp"
print_status "  View logs: kubectl logs -n acme-wp <pod-name>"
echo ""
print_warning "Note: Make sure your DNS points deko.sdlbdcloud.com to the MetalLB IP (192.168.122.210)"
