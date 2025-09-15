terraform {
  required_version = ">= 1.5"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8.0"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

############################################################
# Storage: clone OS volume for each VM from the image source
############################################################
resource "libvirt_volume" "os" {
  for_each = toset(var.vm_names)
  name     = "${each.key}.qcow2"
  pool     = var.pool_name              # e.g., "KvmStorage"
  source   = var.image_url              # URL or local path to qcow2
  format   = "qcow2"
  # Optional grow (must be >= image size)
#  size   = var.disk_size_gb * 1024 * 1024 * 1024
}

############################################################
# Cloud-init ISO for user + SSH key + qemu-guest-agent
############################################################
resource "libvirt_cloudinit_disk" "cloudinit" {
  for_each  = toset(var.vm_names)
  name      = "${each.key}-cloudinit.iso"
  pool      = var.pool_name
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    hostname = each.key
    username = var.ssh_user
    ssh_key  = var.ssh_authorized_key
    packages = var.extra_packages
  })
}

############################################################
# Domain (VM)
############################################################
resource "libvirt_domain" "vm" {
  for_each  = toset(var.vm_names)
  name      = each.key
  memory    = var.memory_mb
  vcpu      = var.vcpu
  autostart = true

  # Make guest CPU closely match host for maximum compatibility
  cpu {
    mode = "host-passthrough"
  }

  qemu_agent = true
  cloudinit  = libvirt_cloudinit_disk.cloudinit[each.key].id

  # NIC: attach to existing libvirt network (virtio model by default)
  network_interface {
    network_name   = var.libvirt_network
    wait_for_lease = true
    # model = "virtio"  # usually default; uncomment if your env needs it
  }

  # Disk: attach the cloned OS volume (virtio by default)
  disk {
    volume_id = libvirt_volume.os[each.key].id
    # scsi = false      # keep virtio (default); set true if you want SCSI
  }

  # Ensure we boot from disk first, then cloud-init ISO
  boot_device {
    dev = ["hd", "cdrom"]
  }

  # Serial console (makes kernel/boot logs visible in console viewer)
  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  # Optional VNC graphics
  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}

