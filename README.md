Deko Infrastructure: Kubernetes HA, CI/CD, and Terraform

Overview
This repository provides end-to-end infrastructure building blocks for a production-grade Kubernetes platform:
- Highly Available Kubernetes cluster using NGINX + Keepalived (VIP) and kubeadm
- CI/CD assets with Helm charts and raw Kubernetes manifests (incl. Argo CD integration)
- Terraform definitions to provision KVM-based infrastructure

Repo structure
- kubernetes/: Step-by-step HA Kubernetes installation guide (load balancer + multi-master)
- ci-cd/helm-chart/: Helm chart and Argo CD application for deploying the stack
- ci-cd/kubernetes-manifests/: Raw manifests for API, database, frontend, HPA/VPA, ingress, MetalLB, etc.
- terraform/kvm-tf/: Terraform for KVM/libvirt provisioning (cloud-init, variables, outputs)
- Monitoring/: Placeholder for monitoring stack (add Grafana/Prometheus here)

Start here
1) Build the HA Kubernetes Cluster
   Follow the consolidated guide at kubernetes/README.md
   - Part A: Configure two LBs (NGINX stream + Keepalived) with a virtual IP for the Kubernetes API
   - Part B: Install containerd, kubeadm/kubelet/kubectl, bootstrap multi-master control-plane, install Calico, join workers

2) Deploy Apps and Platform Components
   Option A — Helm + Argo CD:
   - Review ci-cd/helm-chart/README.md
   - Install/operate Argo CD using ci-cd/helm-chart/argocd-installation.md
   - Bootstrap the application via ci-cd/helm-chart/argocd-application.yaml

   Option B — Raw Kubernetes manifests:
   - Use files under ci-cd/kubernetes-manifests/ (services, deployments, PVCs, ingress, HPA/VPA, MetalLB config, etc.)
   - See scripts like install.sh or argocd-manage.ps1 for examples/automation

3) Provisioning with Terraform (optional)
   For KVM/libvirt-based environments, use terraform/kvm-tf/
   - Configure terraform/kvm-tf/terraform.tfvars (see variables in variables.tf)
   - Apply: terraform init && terraform apply
   - Output artifacts will help you access provisioned VMs (see outputs.tf)

Assumptions and versions
- OS: RHEL/Alma/Rocky family (adjust package commands for other distros)
- Container runtime: containerd (systemd cgroups)
- Kubernetes: pkgs.k8s.io stable v1.34 (update as needed)
- CNI: Calico (defaults to pod CIDR 192.168.0.0/16)
- LB: NGINX stream + Keepalived VRRP for API VIP

Useful links inside this repo
- Kubernetes HA installation: kubernetes/README.md
- Helm chart and Argo CD setup: ci-cd/helm-chart/README.md and ci-cd/helm-chart/argocd-installation.md
- Raw Kubernetes manifests: ci-cd/kubernetes-manifests/
- Terraform for KVM: terraform/kvm-tf/README.md

Troubleshooting tips
- Ensure every node (masters, workers, LBs) shares consistent /etc/hosts or DNS
- Verify VIP moves between LBs and NGINX is healthy before kubeadm init
- Match your pod network CIDR with the CNI configuration
- Open required firewall ports on masters/workers as documented in kubernetes/README.md

Contributing
Contributions are welcome. Please open an issue or PR with a concise description and testing notes.

License
This repository is provided as-is. Add your organization’s license policy here if required.


