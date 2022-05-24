#!/usr/bin/env bash

#region set variables

TARGET_BRANCH=$1
TEMPLATE_VMID=9050
CLOUDINIT_IMAGE_TARGET_VOLUME=prd-network-01-lun01
BOOT_IMAGE_TARGET_VOLUME=prd-network-01-lun01
SNIPPET_TARGET_VOLUME=seichi-prox-backup04
SNIPPET_TARGET_PATH=/mnt/pve/${SNIPPET_TARGET_VOLUME}/snippets
REPOSITORY_RAW_SOURCE_URL="https://raw.githubusercontent.com/GiganticMinecraft/seichi_infra/${TARGET_BRANCH}"
VM_LIST=(
    #vmid #vmname             #cpu #mem
    "1001 seichi-onp-k8s-cp-1 4    8192 "
    "1002 seichi-onp-k8s-cp-2 4    8192 "
    "1003 seichi-onp-k8s-cp-3 4    8192 "
    "1101 seichi-onp-k8s-wk-1 6    12288"
    "1102 seichi-onp-k8s-wk-2 6    12288"
    "1103 seichi-onp-k8s-wk-3 6    12288"
)

#endregion

# ---

#region create-template

# download the image(ubuntu 20.04 LTS)
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# create a new VM and attach Network Adaptor
# vmbr0=Service Network Segment (192.168.0.0/20)
# vmbr1=Storage Network Segment (192.168.16.0/22)
qm create $TEMPLATE_VMID --cores 2 --memory 4096 --net0 virtio,bridge=vmbr0 --net1 virtio,bridge=vmbr1 --name seichi-onp-k8s-template

# import the downloaded disk to $BOOT_IMAGE_TARGET_VOLUME storage
qm importdisk $TEMPLATE_VMID focal-server-cloudimg-amd64.img $BOOT_IMAGE_TARGET_VOLUME

# finally attach the new disk to the VM as scsi drive
qm set $TEMPLATE_VMID --scsihw virtio-scsi-pci --scsi0 $BOOT_IMAGE_TARGET_VOLUME:vm-$TEMPLATE_VMID-disk-0

# add Cloud-Init CD-ROM drive
qm set $TEMPLATE_VMID --ide2 $CLOUDINIT_IMAGE_TARGET_VOLUME:cloudinit

# set the bootdisk parameter to scsi0
qm set $TEMPLATE_VMID --boot c --bootdisk scsi0

# set serial console
qm set $TEMPLATE_VMID --serial0 socket --vga serial0

# migrate to template
qm template $TEMPLATE_VMID

# cleanup
rm focal-server-cloudimg-amd64.img

#endregion

# ---

# region create vm from template

for array in "${VM_LIST[@]}"
do
    echo "${array}" | while read -r vmid vmname cpu mem
    do
        # clone from template
        qm clone "${TEMPLATE_VMID}" "${vmid}" --name "${vmname}" --full true 
        qm set "${vmid}" --cores "${cpu}" --memory "${mem}"

        # resize disk (Resize after cloning, because it takes time to clone a large disk)
        qm resize "${vmid}" scsi0 30G

        # create snippet for cloud-init(user-config)
        # START irregular indent because heredoc
# ----- #
cat > "$SNIPPET_TARGET_PATH"/"$vmname"-user.yaml << EOF
#cloud-config
hostname: ${vmname}
timezone: Asia/Tokyo
manage_etc_hosts: true
chpasswd:
  expire: False
users:
  - default
  - name: cloudinit
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    # mkpasswd --method=SHA-512 --rounds=4096
    # password is zaq12wsx
    passwd: \$6\$rounds=4096\$Xlyxul70asLm\$9tKm.0po4ZE7vgqc.grptZzUU9906z/.vjwcqz/WYVtTwc5i2DWfjVpXb8HBtoVfvSY61rvrs/iwHxREKl3f20
ssh_pwauth: false
ssh_authorized_keys: []
package_upgrade: true
runcmd:
  # set ssh_authorized_keys
  - su - cloudinit -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
  - su - cloudinit -c "curl -sS https://github.com/unchama.keys >> ~/.ssh/authorized_keys"
  - su - cloudinit -c "curl -sS https://github.com/inductor.keys >> ~/.ssh/authorized_keys"
  - su - cloudinit -c "curl -sS https://github.com/kory33.keys >> ~/.ssh/authorized_keys"
  - su - cloudinit -c "chmod 600 ~/.ssh/authorized_keys"
  # run install scripts
  - su - cloudinit -c "curl -s ${REPOSITORY_RAW_SOURCE_URL}/seichi-onp-k8s/cluster-boot-scripts/scripts/nodes/k8s-node-setup.sh > ~/k8s-node-setup.sh"
  - su - cloudinit -c "sudo bash ~/k8s-node-setup.sh ${vmname}"
EOF
# ----- #
        # END irregular indent because heredoc

        # only seichi-onp-k8s-cp-1, append snippet for cloud-init(user-config)
        if [ "${vmname}" = "seichi-onp-k8s-cp-1" ]
        then
            # START irregular indent because heredoc
# --------- #
cat >> "$SNIPPET_TARGET_PATH"/"$vmname"-user.yaml << EOF
  # add kubeconfig to cloudinit user
  - su - cloudinit -c "mkdir -p ~/.kube"
  - su - cloudinit -c "sudo cp /etc/kubernetes/admin.conf ~/.kube/config"
  - su - cloudinit -c "sudo chown cloudinit:cloudinit ~/.kube/config"
  # copy kubeadm-join-config to cloudinit user home directory
  - su - cloudinit -c "sudo cp /root/join_kubeadm_cp.yaml ~/join_kubeadm_cp.yaml"
  - su - cloudinit -c "sudo cp /root/join_kubeadm_wk.yaml ~/join_kubeadm_wk.yaml"
EOF
# --------- #
            # END irregular indent because heredoc
        fi
        
        # download snippet for cloud-init(network)
        curl -s "${REPOSITORY_RAW_SOURCE_URL}/seichi-onp-k8s/cluster-boot-scripts/snippets/${vmname}-network.yaml" > "${SNIPPET_TARGET_PATH}"/"${vmname}"-network.yaml

        # set snippet to vm
        qm set "${vmid}" --cicustom "user=${SNIPPET_TARGET_VOLUME}:snippets/${vmname}-user.yaml,network=${SNIPPET_TARGET_VOLUME}:snippets/${vmname}-network.yaml"

    done
done

# migrate vm
qm migrate 1001 unchama-sv-prox01
qm migrate 1002 unchama-sv-prox02
qm migrate 1003 unchama-sv-prox04
qm migrate 1101 unchama-sv-prox01
qm migrate 1102 unchama-sv-prox02
qm migrate 1103 unchama-sv-prox04

# start vm
## on unchama-sv-prox01
ssh 192.168.16.150 qm start 1001
ssh 192.168.16.150 qm start 1101
## on unchama-sv-prox02
ssh 192.168.16.151 qm start 1002
ssh 192.168.16.151 qm start 1102
## on unchama-sv-prox04
ssh 192.168.16.153 qm start 1003
ssh 192.168.16.153 qm start 1103

# endregion
