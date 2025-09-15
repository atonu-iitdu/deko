Kubernetes HA Cluster Installation Guide (NGINX + Keepalived, kubeadm, Calico)

Overview
This guide describes how to build a highly available Kubernetes cluster using two load balancers (NGINX + Keepalived with a VIP) in front of three control-plane nodes, plus worker nodes. It consolidates and streamlines the steps from Kubernetes_Install_0.txt (load balancer) and Kubernetes_Install.txt (multi-master setup).

Reference topology (example)
- Masters: 192.168.122.121 kubemaster01, 192.168.122.122 kubemaster02, 192.168.122.123 kubemaster03
- Workers: 192.168.122.131 kubeworker01, 192.168.122.132 kubeworker02
- Load balancers: 192.168.122.101 lb1, 192.168.122.102 lb2
- VIP (API): 192.168.122.100 kubeapi (resolves to kubeapi.atonu.com)

Set hostnames and /etc/hosts on every node
Add entries to all masters, workers, and both load balancers so every name resolves everywhere.

```bash
cat <<'EOF' | sudo tee -a /etc/hosts
# Master Nodes
192.168.122.121  kubemaster01.atonu.com  kubemaster01
192.168.122.122  kubemaster02.atonu.com  kubemaster02
192.168.122.123  kubemaster03.atonu.com  kubemaster03

# Worker Nodes
192.168.122.131  kubeworker01.atonu.com  kubeworker01
192.168.122.132  kubeworker02.atonu.com  kubeworker02

# Load Balancers
192.168.122.101  lb1.atonu.com  lb1
192.168.122.102  lb2.atonu.com  lb2

# VIP
192.168.122.100  kubeapi.atonu.com  kubeapi
EOF
```

Part A — Load balancer HA (lb1 and lb2)
Applies to: RHEL/Alma/Rocky family. Adjust package commands if using a different distro.

1) Install NGINX + Keepalived + prerequisites
```bash
sudo dnf install -y nginx keepalived nginx-mod-stream
sudo systemctl enable nginx keepalived

sudo firewall-cmd --permanent --add-protocol=vrrp
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --reload

# Allow binding to the VIP before it is assigned
echo "net.ipv4.ip_nonlocal_bind = 1" | sudo tee /etc/sysctl.d/99-kubeapi.conf
sudo sysctl --system
```

2) Configure NGINX TCP load-balancing for the API server
- Ensure the stream section is enabled in NGINX and use a separate include directory for stream configs.

Append this to /etc/nginx/nginx.conf (keep any existing http{} as-is):
```bash
cat <<'EOF' | sudo tee -a /etc/nginx/nginx.conf
# ... keep your existing http{} if present
stream {
    include /etc/nginx/stream.d/*.conf;
}
EOF
```

Create the stream include directory and kube-apiserver upstream:
```bash
sudo mkdir -p /etc/nginx/stream.d
cat <<'EOF' | sudo tee /etc/nginx/stream.d/kube-apiserver.conf
upstream kube_apiserver {
    least_conn;
    server 192.168.122.121:6443 max_fails=3 fail_timeout=30s;
    server 192.168.122.122:6443 max_fails=3 fail_timeout=30s;
    server 192.168.122.123:6443 max_fails=3 fail_timeout=30s;
}

server {
    # Listen on all addresses (works with VIP via nonlocal bind)
    listen 0.0.0.0:6443;
    proxy_connect_timeout 1s;
    proxy_timeout 3600s;  # long-lived watch connections
    proxy_pass kube_apiserver;
}
EOF

sudo nginx -t
sudo systemctl restart nginx
```

3) Configure Keepalived for VIP failover
Pick the correct NIC (IFACE) for your environment (e.g., enp1s0, ens3, eth0). Replace IFACE below.

lb1 — /etc/keepalived/keepalived.conf
```bash
sudo mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak || true
cat <<'EOF' | sudo tee /etc/keepalived/keepalived.conf
global_defs {
  router_id LB1
}

vrrp_script chk_nginx {
  script "/usr/bin/pgrep -x nginx"
  interval 2
  weight -20
}

vrrp_instance VI_1 {
  state MASTER
  interface IFACE
  virtual_router_id 51
  priority 150
  advert_int 1
  # If multicast VRRP isn't available, configure unicast peers
  # unicast_peer {
  #   192.168.122.102
  # }

  authentication {
    auth_type PASS
    auth_pass 42Secret!
  }

  virtual_ipaddress {
    192.168.122.100/24 dev IFACE label IFACE:1
  }

  track_script {
    chk_nginx
  }
}
EOF
```

lb2 — /etc/keepalived/keepalived.conf
```bash
sudo mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak || true
cat <<'EOF' | sudo tee /etc/keepalived/keepalived.conf
global_defs {
  router_id LB2
}

vrrp_script chk_nginx {
  script "/usr/bin/pgrep -x nginx"
  interval 2
  weight -20
}

vrrp_instance VI_1 {
  state BACKUP
  interface IFACE
  virtual_router_id 51
  priority 100
  advert_int 1
  # If using unicast, mirror peers
  # unicast_peer {
  #   192.168.122.101
  # }

  authentication {
    auth_type PASS
    auth_pass 42Secret!
  }

  virtual_ipaddress {
    192.168.122.100/24 dev IFACE label IFACE:1
  }

  track_script {
    chk_nginx
  }
}
EOF

sudo systemctl enable --now keepalived
```

Quick validation
- The VIP 192.168.122.100 should be present on the MASTER LB.
- After Kubernetes API is up, curl https://kubeapi.atonu.com:6443 should respond; without a client cert it will show an HTTPS error, which is expected.

Part B — Kubernetes multi-master installation
Perform these on all masters and workers unless noted.

1) OS preparation
```bash
# Basic tools & time sync
sudo dnf install -y curl vim socat conntrack ebtables ethtool chrony
sudo systemctl enable --now chronyd

# Disable swap (kubelet requirement)
sudo swapoff -a
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

# Kernel modules & sysctls for Kubernetes networking
cat <<'EOF' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<'EOF' | sudo tee /etc/sysctl.d/99-kubernetes.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
```

2) Install and configure containerd
```bash
sudo dnf -y install containerd || {
  sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  sudo dnf -y install containerd.io
}

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable --now containerd
```

3) Install kubeadm, kubelet, kubectl (pkgs.k8s.io)
```bash
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

cat <<'EOF' | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable kubelet
```

4) Open firewall ports
On masters (control-plane):
```bash
sudo firewall-cmd --permanent --add-port=6443/tcp      # Kubernetes API server
sudo firewall-cmd --permanent --add-port=2379-2380/tcp # etcd client API
sudo firewall-cmd --permanent --add-port=10250/tcp     # kubelet API
sudo firewall-cmd --permanent --add-port=10259/tcp     # kube-scheduler
sudo firewall-cmd --permanent --add-port=10257/tcp     # kube-controller-manager
sudo firewall-cmd --reload
```

On workers:
```bash
sudo firewall-cmd --permanent --add-port=10250/tcp     # kubelet API
sudo firewall-cmd --reload
```

5) Bootstrap the first control plane (run on kubemaster01)
Use the VIP as the control-plane endpoint, advertise the node’s real IP, and choose a pod CIDR that matches your CNI (Calico uses 192.168.0.0/16 by default below).
```bash
kubeadm init \
  --control-plane-endpoint="192.168.122.100:6443" \
  --upload-certs \
  --apiserver-advertise-address=192.168.122.121 \
  --pod-network-cidr=192.168.0.0/16
```

Configure kubectl for the current user (example for root):
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

6) Install Calico CNI
```bash
# Install Calico operator & CRDs
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/tigera-operator.yaml

# Create Calico default resources (IP pool defaults to 192.168.0.0/16)
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/custom-resources.yaml

# Watch Calico come up
watch kubectl get pods -n calico-system
```

7) Join the other control planes (kubemaster02/03)
Generate a join command on an existing control-plane node and run it on the new masters.
```bash
# On a running master, generate join materials
CERT_KEY=$(kubeadm init phase upload-certs --upload-certs | tail -n1)
TOKEN=$(kubeadm token create)
HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
  | openssl rsa -pubin -outform DER 2>/dev/null \
  | openssl dgst -sha256 -hex | awk '{print $2}')

echo "kubeadm join 192.168.122.100:6443 --token $TOKEN \
  --discovery-token-ca-cert-hash sha256:$HASH \
  --control-plane --certificate-key $CERT_KEY"
```
Run the printed join command on kubemaster02 and kubemaster03.

8) Join the workers
```bash
# On a running master, print the worker join command
kubeadm token create --print-join-command
```
Run the printed command on each worker node.

Cluster validation
```bash
kubectl get nodes -o wide
kubectl get pods -A
```

Notes and tips
- Replace IFACE in Keepalived configs with the actual NIC device (e.g., enp1s0).
- Ensure DNS or /etc/hosts entries are consistent across all nodes.
- SELinux is set to permissive here for simplicity; consider proper policy in hardened environments.
- If your L2 network is flat, Calico defaults are typically fine. For VXLAN/IPIP/encapsulation changes, see Calico documentation.
- If VRRP multicast is not supported in your network, switch Keepalived to unicast mode and set unicast peers on both LBs.


