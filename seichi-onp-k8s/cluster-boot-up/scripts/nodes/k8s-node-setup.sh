#!/usr/bin/env bash

set -eu

# special thanks!: https://gist.github.com/inductor/32116c486095e5dde886b55ff6e568c8

function usage() {
    echo "usage> k8s-node-setup.sh [COMMAND]"
    echo "[COMMAND]:"
    echo "  help        show command usage"
    echo "  seichi-onp-k8s-cp-1    run setup script for seichi-onp-k8s-cp-1"
    echo "  seichi-onp-k8s-cp-2    run setup script for seichi-onp-k8s-cp-2"
    echo "  seichi-onp-k8s-cp-3    run setup script for seichi-onp-k8s-cp-3"
    echo "  seichi-onp-k8s-wk-*    run setup script for seichi-onp-k8s-wk-*"
}

case $1 in
    seichi-onp-k8s-cp-1|seichi-onp-k8s-cp-2|seichi-onp-k8s-cp-3|seichi-onp-k8s-wk-*)
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
TARGET_BRANCH=$2

# === (1) 1つ目VIP(既存)の設定 ===
KUBE_API_SERVER_VIP=192.168.32.100
VIP_INTERFACE=ens20
NODE_IPS=( 192.168.32.11 192.168.32.12 192.168.32.13 )

# === (2) 2つ目VIP(LB_VIP2)の設定 ===
KUBE_API_SERVER_VIP2=192.168.0.100
VIP_INTERFACE2=ens18
NODE_IPS_2=( 192.168.0.11 192.168.0.12 192.168.0.13 )

case $1 in
    seichi-onp-k8s-cp-1)
        KEEPALIVED_STATE=MASTER
        KEEPALIVED_PRIORITY=101
        KEEPALIVED_UNICAST_SRC_IP=${NODE_IPS[0]}
        KEEPALIVED_UNICAST_PEERS=( "${NODE_IPS[1]}" "${NODE_IPS[2]}" )
        ;;
    seichi-onp-k8s-cp-2)
        KEEPALIVED_STATE=BACKUP
        KEEPALIVED_PRIORITY=99
        KEEPALIVED_UNICAST_SRC_IP=${NODE_IPS[1]}
        KEEPALIVED_UNICAST_PEERS=( "${NODE_IPS[0]}" "${NODE_IPS[2]}" )
        ;;
    seichi-onp-k8s-cp-3)
        KEEPALIVED_STATE=BACKUP
        KEEPALIVED_PRIORITY=97
        KEEPALIVED_UNICAST_SRC_IP=${NODE_IPS[2]}
        KEEPALIVED_UNICAST_PEERS=( "${NODE_IPS[0]}" "${NODE_IPS[1]}" )
        ;;
    seichi-onp-k8s-wk-*)
        ;;
    *)
        exit 1
        ;;
esac

case $1 in
    seichi-onp-k8s-cp-1)
        LB_VIP2_STATE=MASTER
        LB_VIP2_PRIORITY=100
        LB_VIP2_UNICAST_SRC_IP=${NODE_IPS_2[0]}
        LB_VIP2_UNICAST_PEERS=( "${NODE_IPS_2[1]}" "${NODE_IPS_2[2]}" )
        ;;
    seichi-onp-k8s-cp-2)
        LB_VIP2_STATE=BACKUP
        LB_VIP2_PRIORITY=98
        LB_VIP2_UNICAST_SRC_IP=${NODE_IPS_2[1]}
        LB_VIP2_UNICAST_PEERS=( "${NODE_IPS_2[0]}" "${NODE_IPS_2[2]}" )
        ;;
    seichi-onp-k8s-cp-3)
        LB_VIP2_STATE=BACKUP
        LB_VIP2_PRIORITY=96
        LB_VIP2_UNICAST_SRC_IP=${NODE_IPS_2[2]}
        LB_VIP2_UNICAST_PEERS=( "${NODE_IPS_2[0]}" "${NODE_IPS_2[1]}" )
        ;;
    seichi-onp-k8s-wk-*)
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

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
    "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    \$(. /etc/os-release && echo "\$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's#sandbox_image = "registry.k8s.io/pause:3.8"#sandbox_image = "registry.k8s.io/pause:3.10"#g' /etc/containerd/config.toml
if grep -q "SystemdCgroup = true" "/etc/containerd/config.toml"; then
    echo "Config found, skip rewriting..."
else
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
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
net.ipv4.conf.*.rp_filter = 0
net.ipv4.tcp_fastopen=3
fs.inotify.max_user_watches=65536
fs.inotify.max_user_instances=8192
EOF
sysctl --system

# Install kubeadm
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get install -y kubeadm=1.32.1-1.1 kubectl=1.32.1-1.1 kubelet=1.32.1-1.1
apt-mark hold kubelet kubectl

# Disable swap
swapoff -a

cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 10
EOF

# Ends except worker-plane
case $1 in
    seichi-onp-k8s-wk-*)
        exit 0
        ;;
    seichi-onp-k8s-cp-1|seichi-onp-k8s-cp-2|seichi-onp-k8s-cp-3)
        ;;
    *)
        exit 1
        ;;
esac

# Install HAProxy
apt-get install -y --no-install-recommends software-properties-common
add-apt-repository ppa:vbernat/haproxy-3.1 -y
sudo apt-get install -y haproxy=3.1.\*

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
    bind ${KUBE_API_SERVER_VIP}:8443
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
apt-get -y install keepalived

cat > /usr/local/bin/check_haproxy.sh <<'EOS'
#!/bin/bash
/usr/bin/nc -z -w1 127.0.0.1 8443
if [ $? -eq 0 ]; then
    exit 0
else
    exit 1
fi
EOS
chmod +x /usr/local/bin/check_haproxy.sh

# (CHANGED) keepalived.conf: 2つの vrrp_instance を定義 + ヘルスチェックをnc方式へ
cat > /etc/keepalived/keepalived.conf <<EOF
vrrp_script chk_haproxy {
    script "/usr/local/bin/check_haproxy.sh"
    interval 2
    weight 2
}

#=== LB_VIP (VRID=51) ===
vrrp_instance LB_VIP {
    interface ${VIP_INTERFACE}
    state ${KEEPALIVED_STATE}
    priority ${KEEPALIVED_PRIORITY}
    virtual_router_id 51

    smtp_alert
    authentication {
        auth_type AH
        auth_pass zaq12wsx
    }

    unicast_src_ip ${KEEPALIVED_UNICAST_SRC_IP}
    unicast_peer {
$( for peer in "${KEEPALIVED_UNICAST_PEERS[@]}"; do
    echo "        $peer"
done )
    }

    virtual_ipaddress {
        ${KUBE_API_SERVER_VIP}
    }

    track_script {
        chk_haproxy
    }
}

#=== LB_VIP2 (VRID=52) ===
vrrp_instance LB_VIP2 {
    interface ${VIP_INTERFACE2}
    state ${LB_VIP2_STATE}
    priority ${LB_VIP2_PRIORITY}
    virtual_router_id 52

    smtp_alert
    authentication {
        auth_type AH
        auth_pass zaq12wsx
    }

    unicast_src_ip ${LB_VIP2_UNICAST_SRC_IP}
    unicast_peer {
$( for peer in "${LB_VIP2_UNICAST_PEERS[@]}"; do
    echo "        $peer"
done )
    }

    virtual_ipaddress {
        ${KUBE_API_SERVER_VIP2}
    }

    track_script {
        chk_haproxy
    }
}
EOF

# Create keepalived user
groupadd -r keepalived_script || true
useradd -r -s /sbin/nologin -g keepalived_script -M keepalived_script || true

echo "keepalived_script ALL=(ALL) NOPASSWD: /usr/bin/killall" >> /etc/sudoers

# Enable VIP services
systemctl enable keepalived --now
systemctl enable haproxy --now

# Reload VIP services
systemctl reload keepalived
systemctl reload haproxy

# Pull images first
kubeadm config images pull

# install k9s
wget https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_Linux_amd64.tar.gz -O - | tar -zxvf - k9s && sudo mv ./k9s /usr/local/bin/

# Ends except first-control-plane
case $1 in
    seichi-onp-k8s-cp-1)
        ;;
    seichi-onp-k8s-cp-2|seichi-onp-k8s-cp-3)
        exit 0
        ;;
    *)
        exit 1
        ;;
esac

# Set kubeadm bootstrap token using openssl
KUBEADM_BOOTSTRAP_TOKEN=$(openssl rand -hex 3).$(openssl rand -hex 8)
KUBEADM_LOCAL_ENDPOINT=$(ip -4 addr show ens20 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | awk 'NR==1{print $1}')

# Set init configuration for the first control plane
cat > "$HOME"/init_kubeadm.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
bootstrapTokens:
- token: "$KUBEADM_BOOTSTRAP_TOKEN"
    description: "kubeadm bootstrap token"
    ttl: "24h"
nodeRegistration:
    criSocket: "unix:///var/run/containerd/containerd.sock"
    kubeletExtraArgs:
    node-ip: "$KUBEADM_LOCAL_ENDPOINT"
localAPIEndpoint:
    advertiseAddress: "$KUBEADM_LOCAL_ENDPOINT"
    bindPort: 6443
skipPhases:
    - addon/kube-proxy
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
    serviceSubnet: "10.96.64.0/18"
    podSubnet: "10.96.128.0/18"
etcd:
    local:
    extraArgs:
        listen-metrics-urls: http://0.0.0.0:2381
kubernetesVersion: "v1.32.1"
controlPlaneEndpoint: "${KUBE_API_SERVER_VIP}:8443"
apiServer:
    certSANs:
        - k8s-api.onp-k8s.admin.local-tunnels.seichi.click
controllerManager:
    extraArgs:
        bind-address: "0.0.0.0"
scheduler:
    extraArgs:
        bind-address: "0.0.0.0"
clusterName: "unchama-cloud"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: "systemd"
protectKernelDefaults: true
EOF

# Install Kubernetes without kube-proxy
kubeadm init --config "$HOME"/init_kubeadm.yaml --skip-phases=addon/kube-proxy --ignore-preflight-errors=NumCPU,Mem

mkdir -p "$HOME"/.kube
cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Install Helm CLI
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install Cilium Helm chart
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium \
    --namespace kube-system \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=${KUBE_API_SERVER_VIP} \
    --set k8sServicePort=8443 \
    --set bgpControlPlane.enabled=true \
    --set ipam.mode=cluster-pool \
    --set ipam.operator.clusterPoolIPv4PodCIDRList=["10.96.128.0/18"]

# Generate control plane certificate
KUBEADM_UPLOADED_CERTS=$(kubeadm init phase upload-certs --upload-certs | tail -n 1)

# clone repo
git clone -b "${TARGET_BRANCH}" https://github.com/GiganticMinecraft/seichi_infra.git "$HOME"/seichi_infra

# add join information to ansible hosts variable
echo "kubeadm_bootstrap_token: $KUBEADM_BOOTSTRAP_TOKEN" >> "$HOME"/seichi_infra/seichi-onp-k8s/cluster-boot-up/ansible/hosts/k8s-servers/group_vars/all.yaml
echo "kubeadm_uploaded_certs: $KUBEADM_UPLOADED_CERTS" >> "$HOME"/seichi_infra/seichi-onp-k8s/cluster-boot-up/ansible/hosts/k8s-servers/group_vars/all.yaml

# install ansible
sudo apt-get install -y ansible git sshpass

# export ansible.cfg target
export ANSIBLE_CONFIG="$HOME"/seichi_infra/seichi-onp-k8s/cluster-boot-up/ansible/ansible.cfg

# run ansible-playbook
ansible-galaxy role install -r "$HOME"/seichi_infra/seichi-onp-k8s/cluster-boot-up/ansible/roles/requirements.yaml
ansible-galaxy collection install -r "$HOME"/seichi_infra/seichi-onp-k8s/cluster-boot-up/ansible/roles/requirements.yaml
ansible-playbook -i "$HOME"/seichi_infra/seichi-onp-k8s/cluster-boot-up/ansible/hosts/k8s-servers/inventory "$HOME"/seichi_infra/seichi-onp-k8s/cluster-boot-up/ansible/site.yaml
