pool_name          = "KvmStorage" # confirm with: virsh pool-list --all
vm_names           = [
  "kubemaster01",
  "kubemaster02",
  "kubemaster03",
  "kubeworker01",
  "kubeworker02",
]
ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHpRIddnC1mJMTZNYyPo4bWIhXSQUW+9DIW0vJHPB4RIeJuBpFyH6BVX2ibDIXDQ+TR987UaCeQMWagoT2O/1l0bpu+rtos70SuZSrR5din4ykK3oNkdNW/FrHWpYm/DG8ikjqJpGxxD8qzebvVo4Kne5RZiWpfHBY8Rg4914LHygx2OcNFZro7UUQZH6sU908pBmvIigj4a0v+r8aUgexb8FbaqsJ3CSsJ9THaBDhw5ArOCqyU211gQwYmhoisA7aQw2k4qzCLxAZNRNpr7gP5QyAfZlAhhLyO5B7usPVGAhchKfu3mMF465lhQbJkryyiZ7Ys4+c6BebJJzxYm+fMTPSrZXYitc5y6we0oh/eD+zUdr7u8t8ZfNQZiiOW7udM+KjtCsMHx2V3uQgQvqkC8kK0On8xhFAfBrnVtxHIQvxepehpDEzBRjPYuhifVw91UVBpmXoSSodJU7uNkrarVq45RAalbSatPpu0lLvKjafIWOkfQ+0+rLAhUW3TMk= root@sel-physical.atonu.com"
memory_mb          = 4096
vcpu               = 2
disk_size_gb       = 30

