#/bin/bash -eu

# special thanks!: https://gist.github.com/inductor/32116c486095e5dde886b55ff6e568c8

function usage() {
    echo "usage> k8s-node-setup.sh [COMMAND]"
    echo "[COMMAND]:"
    echo "  help        show command usage"
    echo "  k8s-cp-1    run setup script for k8s-cp-1"
    echo "  k8s-cp-2    run setup script for k8s-cp-2"
    echo "  k8s-cp-3    run setup script for k8s-cp-3"
    echo "  k8s-wk-*    run setup script for k8s-wk-*"
}

case $1 in
    k8s-cp-1|k8s-cp-2|k8s-cp-3|k8s-wk-*)
        ;;
    help)
        usage
        exit 255
        ;;
    *)
        usage
        exit 255
        ;;
esac

# Set global variables
KUBE_API_SERVER_VIP=192.168.18.100
NODE_IPS=( 192.168.18.11 192.168.18.12 192.168.18.13 )

# set per-node variables
case $1 in
    k8s-cp-1)
        KEEPALIVED_STATE=MASTER
        KEEPALIVED_PRIORITY=101
        KEEPALIVED_UNICAST_SRC_IP=${NODE_IPS[0]}
        KEEPALIVED_UNICAST_PEERS=( ${NODE_IPS[1]} ${NODE_IPS[2]} )
        ;;
    k8s-cp-2)
        KEEPALIVED_STATE=BACKUP
        KEEPALIVED_PRIORITY=99
        KEEPALIVED_UNICAST_SRC_IP=${NODE_IPS[1]}
        KEEPALIVED_UNICAST_PEERS=( ${NODE_IPS[0]} ${NODE_IPS[2]} )
        ;;
    k8s-cp-3)
        KEEPALIVED_STATE=BACKUP
        KEEPALIVED_PRIORITY=97
        KEEPALIVED_UNICAST_SRC_IP=${NODE_IPS[2]}
        KEEPALIVED_UNICAST_PEERS=( ${NODE_IPS[0]} ${NODE_IPS[1]} )
        ;;
    k8s-wk-*)
        ;;
    *)
        exit 1
        ;;
esac

# Install Containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

## Install containerd
sudo apt-get update && sudo apt-get install -y containerd

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default > /etc/containerd/config.toml

if grep -q "SystemdCgroup = true" "/etc/containerd/config.toml"; then
echo "Config found, skip rewriting..."
else
sed -i -e "s/SystemdCgroup \= false/SystemdCgroup \= true/g" /etc/containerd/config.toml
fi

sudo systemctl restart containerd

# Modify kernel parameters for Kubernetes
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.overcommit_memory = 1
vm.panic_on_oom = 0
kernel.panic = 10
kernel.panic_on_oops = 1
kernel.keys.root_maxkeys = 1000000
kernel.keys.root_maxbytes = 25000000
EOF
sysctl --system

# Install kubeadm
apt-get update && apt-get install -y apt-transport-https curl gnupg2
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet=1.23.6-00 kubeadm=1.23.6-00 kubectl=1.23.6-00
apt-mark hold kubelet kubeadm kubectl

# Disable swap
swapoff -a

# Ends except worker-plane
case $1 in
    k8s-wk-*)
        exit 0
        ;;
    k8s-cp-1|k8s-cp-2|k8s-cp-3)
        ;;
    *)
        exit 1
        ;;
esac

# Install HAProxy
apt-get install -y --no-install-recommends software-properties-common
add-apt-repository ppa:vbernat/haproxy-2.4 -y
sudo apt-get install -y haproxy=2.4.\*

cat > /etc/haproxy/haproxy.cfg <<EOF
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http
frontend k8s-api
    bind ${KUBE_API_SERVER_VIP}:6443
    mode tcp
    option tcplog
    default_backend k8s-api

backend k8s-api
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    server k8s-api-1 ${NODE_IPS[0]}:6443 check
    server k8s-api-2 ${NODE_IPS[1]}:6443 check
    server k8s-api-3 ${NODE_IPS[2]}:6443 check
EOF

# Install Keepalived
echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
sysctl -p

apt-get update && apt-get -y install keepalived

cat > /etc/keepalived/keepalived.conf <<EOF
# Define the script used to check if haproxy is still working
vrrp_script chk_haproxy { 
    script "/usr/bin/killall -0 haproxy"
    interval 2 
    weight 2 
}

# Configuration for Virtual Interface
vrrp_instance LB_VIP {
    interface ens19
    state ${KEEPALIVED_STATE}
    priority ${KEEPALIVED_PRIORITY}
    virtual_router_id 51

    smtp_alert          # Enable Notifications Via Email

    authentication {
        auth_type AH
        auth_pass zaq12wsx	# Password for accessing vrrpd. Same on all devices
    }
    unicast_src_ip ${KEEPALIVED_UNICAST_SRC_IP} # Private IP address of master
    unicast_peer {
        ${KEEPALIVED_UNICAST_PEERS[0]}		# Private IP address of the backup haproxy
        ${KEEPALIVED_UNICAST_PEERS[1]}		# Private IP address of the backup haproxy
    }

    # The virtual ip address shared between the two loadbalancers
    virtual_ipaddress {
        ${KUBE_API_SERVER_VIP}
    }

    # Use the Defined Script to Check whether to initiate a fail over
    track_script {
        chk_haproxy
    }
}
EOF

# Enable VIP services
systemctl enable keepalived --now
systemctl enable haproxy --now

# Ends except first-control-plane
case $1 in
    k8s-cp-1)
        ;;
    k8s-cp-2|k8s-cp-3)
        exit 0
        ;;
    *)
        exit 1
        ;;
esac

# Set kubeadm bootstrap token using openssl
KUBEADM_BOOTSTRAP_TOKEN=$(openssl rand -hex 3).$(openssl rand -hex 8)

# Set init configuration for the first control plane
cat > $HOME/init_kubeadm.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
bootstrapTokens:
- token: "$KUBEADM_BOOTSTRAP_TOKEN"
  description: "kubeadm bootstrap token"
  ttl: "24h"
nodeRegistration:
  criSocket: "/var/run/containerd/containerd.sock"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
  serviceSubnet: "10.96.0.0/16"
  podSubnet: "10.128.0.0/16"
kubernetesVersion: "v1.23.6"
controlPlaneEndpoint: "${KUBE_API_SERVER_VIP}:6443"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: "systemd"
protectKernelDefaults: true
EOF

# Pull images first
kubeadm config images pull

# Install Kubernetes without kube-proxy
kubeadm init --config $HOME/init_kubeadm.yaml --skip-phases=addon/kube-proxy --ignore-preflight-errors=NumCPU,Mem

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Install Helm CLI
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install Cilium Helm chart
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium \
    --namespace kube-system \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=${KUBE_API_SERVER_VIP} \
    --set k8sServicePort=6443

# Install MetalLB Helm Chart
cat > $HOME/metallb_values.yaml <<EOF
configInline:
  address-pools:
   - name: default
     protocol: layer2
     addresses:
     - 192.168.8.128/25
EOF
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -f $HOME/metallb_values.yaml

# Generate control plane certificate
KUBEADM_UPLOADED_CERTS=$(kubeadm init phase upload-certs --upload-certs | tail -n 1)

# Set join configuration for other control plane nodes
cat > $HOME/join_kubeadm_cp.yaml <<EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: "systemd"
protectKernelDefaults: true
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
nodeRegistration:
  criSocket: "/var/run/containerd/containerd.sock"
discovery:
  bootstrapToken:
    apiServerEndpoint: "${KUBE_API_SERVER_VIP}:6443"
    token: "$KUBEADM_BOOTSTRAP_TOKEN"
    unsafeSkipCAVerification: true
controlPlane:
  certificateKey: "$KUBEADM_UPLOADED_CERTS"
EOF

# Set join configuration for worker nodes
cat > $HOME/join_kubeadm_wk.yaml <<EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: "systemd"
protectKernelDefaults: true
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
nodeRegistration:
  criSocket: "/var/run/containerd/containerd.sock"
discovery:
  bootstrapToken:
    apiServerEndpoint: "${KUBE_API_SERVER_VIP}:6443"
    token: "$KUBEADM_BOOTSTRAP_TOKEN"
    unsafeSkipCAVerification: true
EOF
