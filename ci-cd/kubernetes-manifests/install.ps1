# ACME WordPress 3-Tier Application Installation Script (PowerShell)
# This script installs all required components and the application

param(
    [switch]$SkipPrerequisites
)

Write-Host "🚀 Starting ACME WordPress 3-Tier Application Installation..." -ForegroundColor Blue

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if kubectl is installed
try {
    $null = Get-Command kubectl -ErrorAction Stop
    Write-Success "kubectl is installed"
} catch {
    Write-Error "kubectl is not installed. Please install kubectl first."
    exit 1
}

# Check if cluster is accessible
try {
    $null = kubectl cluster-info 2>$null
    Write-Success "Kubernetes cluster is accessible"
} catch {
    Write-Error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
}

if (-not $SkipPrerequisites) {
    # Install MetalLB
    Write-Status "Installing MetalLB..."
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

    # Wait for MetalLB to be ready
    Write-Status "Waiting for MetalLB to be ready..."
    kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=300s
    Write-Success "MetalLB installed successfully"

    # Install Nginx Ingress Controller
    Write-Status "Installing Nginx Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

    # Wait for Nginx Ingress to be ready
    Write-Status "Waiting for Nginx Ingress Controller to be ready..."
    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s
    Write-Success "Nginx Ingress Controller installed successfully"

    # Install VPA (Optional)
    Write-Status "Installing VPA (Vertical Pod Autoscaler)..."
    kubectl apply -f https://github.com/kubernetes/autoscaler/releases/download/vertical-pod-autoscaler-0.14.0/vpa-release.yaml
    Write-Success "VPA installed successfully"
}

# Deploy the application
Write-Status "Deploying ACME WordPress Application..."

# Apply all manifests in order
$manifests = Get-ChildItem -Path "*.yaml" | Sort-Object Name
foreach ($manifest in $manifests) {
    Write-Status "Applying $($manifest.Name)..."
    kubectl apply -f $manifest.Name
}

Write-Success "All manifests applied successfully"

# Wait for pods to be ready
Write-Status "Waiting for application pods to be ready..."
kubectl wait --namespace acme-wp --for=condition=ready pod --selector=app=acme-wp --timeout=600s
Write-Success "Application pods are ready"

# Get application status
Write-Status "Application Status:"
Write-Host ""
kubectl get pods -n acme-wp
Write-Host ""
kubectl get svc -n acme-wp
Write-Host ""
kubectl get ingress -n acme-wp

# Get ArgoCD admin password if ArgoCD is installed
try {
    $null = kubectl get namespace argocd 2>$null
    Write-Status "ArgoCD is installed. Getting admin password..."
    $argocdPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
    if ($argocdPassword) {
        Write-Success "ArgoCD Admin Password: $argocdPassword"
        Write-Status "Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    }
} catch {
    # ArgoCD not installed, continue
}

Write-Host ""
Write-Success "🎉 Installation completed successfully!"
Write-Host ""
Write-Status "Application Access:"
Write-Status "  External: http://deko.sdlbdcloud.com"
Write-Status "  Local: kubectl port-forward -n acme-wp svc/acme-wp-frontend 8005:80"
Write-Host ""
Write-Status "Useful Commands:"
Write-Status "  Check pods: kubectl get pods -n acme-wp"
Write-Status "  Check services: kubectl get svc -n acme-wp"
Write-Status "  Check ingress: kubectl get ingress -n acme-wp"
Write-Status "  Check HPA: kubectl get hpa -n acme-wp"
Write-Status "  Check VPA: kubectl get vpa -n acme-wp"
Write-Status "  View logs: kubectl logs -n acme-wp <pod-name>"
Write-Host ""
Write-Warning "Note: Make sure your DNS points deko.sdlbdcloud.com to the MetalLB IP (192.168.122.210)"
