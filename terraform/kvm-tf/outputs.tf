output "vm_names" {
  description = "All VM names"
  value       = keys(libvirt_domain.vm)
}

output "vm_ips" {
  description = "Primary IPs by VM name"
  value = {
    for name, dom in libvirt_domain.vm :
    name => try(dom.network_interface[0].addresses[0], null)
  }
}

