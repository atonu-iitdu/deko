Deko Infrastructure (Kubernetes HA, CI/CD, Terraform)

What this repo provides
- HA Kubernetes cluster with NGINX + Keepalived (VIP), kubeadm, Calico
- CI/CD with Helm chart, Argo CD app, and raw Kubernetes manifests
- Terraform for KVM/libvirt provisioning

Get started
1) Create the cluster
   See kubernetes/README.md (LB + multi-master + Calico, step-by-step)

2) Deploy apps
   - Helm + Argo CD: ci-cd/helm-chart/ (see argocd-installation.md and argocd-application.yaml)
   - Or use raw manifests: ci-cd/kubernetes-manifests/

3) (Optional) Provision infra with Terraform
   terraform/kvm-tf/ (configure terraform.tfvars, then terraform init && terraform apply)

Links
- Kubernetes guide: kubernetes/README.md
- Helm/Argo: ci-cd/helm-chart/
- Manifests: ci-cd/kubernetes-manifests/
- Terraform: terraform/kvm-tf/