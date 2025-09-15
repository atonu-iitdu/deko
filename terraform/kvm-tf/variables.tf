variable "libvirt_uri" {
  description = "Libvirt connection URI"
  type        = string
  default     = "qemu:///system"
}

variable "pool_name" {
  description = "Existing libvirt storage pool name"
  type        = string
  default     = "KvmStorage" # change if your pool is named differently
}

variable "vm_name" {
  description = "VM name"
  type        = string
  default     = "dev-kvm-01"
}

variable "vm_names" {
  description = "List of VM names to create"
  type        = list(string)
  default     = [
    "kubemaster01",
    "kubemaster02",
    "kubemaster03",
    "kubeworker01",
    "kubeworker02",
  ]
}

variable "image_url" {
  description = "Cloud image URL or local path"
  type        = string
  # default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  default = "/kvmStorage/KWorker-03_192.168.122.26"
}

variable "disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 20
}

variable "memory_mb" {
  description = "RAM in MiB"
  type        = number
  default     = 2048
}

variable "vcpu" {
  description = "vCPU count"
  type        = number
  default     = 2
}

variable "libvirt_network" {
  description = "Libvirt network to attach"
  type        = string
  default     = "default"
}

variable "ssh_user" {
  description = "Login username created by cloud-init"
  type        = string
  default     = "ubuntu" # use 'cloud-user' for Alma/CentOS
}

variable "ssh_authorized_key" {
  description = "Your SSH public key"
  type        = string
  sensitive   = true
}

variable "extra_packages" {
  description = "Extra packages to install via cloud-init"
  type        = list(string)
  default     = ["qemu-guest-agent"]
}

