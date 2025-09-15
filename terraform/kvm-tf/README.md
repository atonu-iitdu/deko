# KVM Terraform Configuration

## Purpose
This Terraform configuration deploys 5 virtual machines using libvirt/KVM for a Kubernetes cluster setup.

## Objective
Create 5 VMs with the following names:
- `kubemaster01`, `kubemaster02`, `kubemaster03` (Kubernetes master nodes)
- `kubeworker01`, `kubeworker02` (Kubernetes worker nodes)

## Files
- `main.tf` - Main Terraform resources (VMs, volumes, cloud-init)
- `variables.tf` - Input variables and their defaults
- `outputs.tf` - Output VM names and IP addresses
- `terraform.tfvars` - Variable values for deployment
- `cloud-init.yaml` - Cloud-init configuration for VM setup

## Usage
```bash
terraform init
terraform plan
terraform apply
```

## Requirements
- libvirt/KVM environment
- Storage pool named "KvmStorage"
- Valid cloud image or existing VM template
