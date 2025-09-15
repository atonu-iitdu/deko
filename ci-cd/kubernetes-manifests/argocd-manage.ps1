# ArgoCD Application Management Script
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("create", "update", "delete", "sync", "status")]
    [string]$Action,
    
    [string]$AppName = "acme-wp",
    [string]$Namespace = "argocd",
    [string]$ManifestFile = "argocd-application-fixed.yaml"
)

Write-Host "🔧 ArgoCD Application Management" -ForegroundColor Blue

function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

switch ($Action) {
    "create" {
        Write-Status "Creating ArgoCD Application..."
        try {
            kubectl apply -f $ManifestFile
            Write-Success "Application created successfully"
        } catch {
            Write-Error "Failed to create application: $_"
        }
    }
    
    "update" {
        Write-Status "Updating ArgoCD Application..."
        try {
            kubectl apply -f $ManifestFile
            Write-Success "Application updated successfully"
        } catch {
            Write-Error "Failed to update application: $_"
        }
    }
    
    "delete" {
        Write-Status "Deleting ArgoCD Application..."
        try {
            kubectl delete application $AppName -n $Namespace
            Write-Success "Application deleted successfully"
        } catch {
            Write-Error "Failed to delete application: $_"
        }
    }
    
    "sync" {
        Write-Status "Syncing ArgoCD Application..."
        try {
            kubectl patch application $AppName -n $Namespace --type merge -p '{"operation":{"sync":{"syncStrategy":{"force":true}}}}'
            Write-Success "Application sync triggered successfully"
        } catch {
            Write-Error "Failed to sync application: $_"
        }
    }
    
    "status" {
        Write-Status "Checking ArgoCD Application Status..."
        try {
            kubectl get application $AppName -n $Namespace -o wide
            Write-Host ""
            kubectl describe application $AppName -n $Namespace
        } catch {
            Write-Error "Failed to get application status: $_"
        }
    }
}

Write-Host ""
Write-Status "Useful Commands:"
Write-Status "  Create: .\argocd-manage.ps1 -Action create"
Write-Status "  Update: .\argocd-manage.ps1 -Action update"
Write-Status "  Delete: .\argocd-manage.ps1 -Action delete"
Write-Status "  Sync:   .\argocd-manage.ps1 -Action sync"
Write-Status "  Status: .\argocd-manage.ps1 -Action status"
