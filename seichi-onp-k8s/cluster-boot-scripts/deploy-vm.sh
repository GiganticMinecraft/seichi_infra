#!/usr/bin/env bash

# region00 : set variables

TEMPLATE_VMID=9050
CLOUDINIT_IMAGE_TARGET_VOLUME=prd-network-01-lun01
BOOT_IMAGE_TARGET_VOLUME=prd-network-01-lun01
SNIPPET_TARGET_VOLUME=seichi-prox-backup04
SNIPPET_TARGET_PATH=/mnt/pve/seichi-prox-backup04/snippets
SNIPPET_SOURCE_URL="https://raw.githubusercontent.com/GiganticMinecraft/seichi_infra/deploy-k8s-on-premises/seichi-onp-k8s/cluster-boot-scripts/snippets"

# end region

# ---

# region01 : create-template

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

# end region

# ---

# region02 : create vm from template

# clone from template
qm clone $TEMPLATE_VMID 1001 --name seichi-onp-k8s-cp-1 --full true 
qm set 1001 --cores 4 --memory 8192
# resize disk (Resize after cloning, because it takes time to clone a large disk)
qm resize 1001 scsi0 30G
# set snippets
curl -s $SNIPPET_SOURCE_URL/seichi-onp-k8s-cp-1-user.yaml > $SNIPPET_TARGET_PATH/seichi-onp-k8s-cp-1-user.yaml
curl -s $SNIPPET_SOURCE_URL/seichi-onp-k8s-cp-1-network.yaml > $SNIPPET_TARGET_PATH/seichi-onp-k8s-cp-1-network.yaml
qm set 1001 --cicustom "user=$SNIPPET_TARGET_VOLUME:snippets/seichi-onp-k8s-cp-1-user.yaml,network=$SNIPPET_TARGET_VOLUME:snippets/seichi-onp-k8s-cp-1-network.yaml"

# clone from template
qm clone $TEMPLATE_VMID 1002 --name seichi-onp-k8s-cp-2 --full true
qm set 1002 --cores 4 --memory 8192
# resize disk (Resize after cloning, because it takes time to clone a large disk)
qm resize 1002 scsi0 30G
# set snippets
curl -s $SNIPPET_SOURCE_URL/seichi-onp-k8s-cp-2-user.yaml > $SNIPPET_TARGET_PATH/seichi-onp-k8s-cp-2-user.yaml
curl -s $SNIPPET_SOURCE_URL/seichi-onp-k8s-cp-2-network.yaml > $SNIPPET_TARGET_PATH/seichi-onp-k8s-cp-2-network.yaml
qm set 1002 --cicustom "user=$SNIPPET_TARGET_VOLUME:snippets/seichi-onp-k8s-cp-2-user.yaml,network=$SNIPPET_TARGET_VOLUME:snippets/seichi-onp-k8s-cp-2-network.yaml"

# clone from template
qm clone $TEMPLATE_VMID 1003 --name seichi-onp-k8s-cp-3 --full true
qm set 1003 --cores 4 --memory 8192
# resize disk (Resize after cloning, because it takes time to clone a large disk)
qm resize 1003 scsi0 30G
# set snippets
curl -s $SNIPPET_SOURCE_URL/seichi-onp-k8s-cp-3-user.yaml > $SNIPPET_TARGET_PATH/seichi-onp-k8s-cp-3-user.yaml
curl -s $SNIPPET_SOURCE_URL/seichi-onp-k8s-cp-3-network.yaml > $SNIPPET_TARGET_PATH/seichi-onp-k8s-cp-3-network.yaml
qm set 1003 --cicustom "user=$SNIPPET_TARGET_VOLUME:snippets/seichi-onp-k8s-cp-3-user.yaml,network=$SNIPPET_TARGET_VOLUME:snippets/seichi-onp-k8s-cp-3-network.yaml"

# clone from template
qm clone $TEMPLATE_VMID 1101 --name seichi-onp-k8s-wk-1 --full true
qm set 1101 --cores 6 --memory 12288
# resize disk (Resize after cloning, because it takes time to clone a large disk)
qm resize 1101 scsi0 30G
# set snippets
curl -s $SNIPPET_SOURCE_URL/seichi-onp-k8s-wk-1-user.yaml > $SNIPPET_TARGET_PATH/seichi-onp-k8s-wk-1-user.yaml
curl -s $SNIPPET_SOURCE_URL/seichi-onp-k8s-wk-1-network.yaml > $SNIPPET_TARGET_PATH/seichi-onp-k8s-wk-1-network.yaml
qm set 1101 --cicustom "user=$SNIPPET_TARGET_VOLUME:snippets/seichi-onp-k8s-wk-1-user.yaml,network=$SNIPPET_TARGET_VOLUME:snippets/seichi-onp-k8s-wk-1-network.yaml"

# clone from template
qm clone $TEMPLATE_VMID 1102 --name seichi-onp-k8s-wk-2 --full true
qm set 1102 --cores 6 --memory 12288
# resize disk (Resize after cloning, because it takes time to clone a large disk)
qm resize 1102 scsi0 30G
# set snippets
curl -s $SNIPPET_SOURCE_URL/seichi-onp-k8s-wk-2-user.yaml > $SNIPPET_TARGET_PATH/seichi-onp-k8s-wk-2-user.yaml
curl -s $SNIPPET_SOURCE_URL/seichi-onp-k8s-wk-2-network.yaml > $SNIPPET_TARGET_PATH/seichi-onp-k8s-wk-2-network.yaml
qm set 1102 --cicustom "user=$SNIPPET_TARGET_VOLUME:snippets/seichi-onp-k8s-wk-2-user.yaml,network=$SNIPPET_TARGET_VOLUME:snippets/seichi-onp-k8s-wk-2-network.yaml"

# clone from template
qm clone $TEMPLATE_VMID 1103 --name seichi-onp-k8s-wk-3 --full true
qm set 1103 --cores 6 --memory 12288
# resize disk (Resize after cloning, because it takes time to clone a large disk)
qm resize 1103 scsi0 30G
# set snippets
curl -s $SNIPPET_SOURCE_URL/seichi-onp-k8s-wk-3-user.yaml > $SNIPPET_TARGET_PATH/seichi-onp-k8s-wk-3-user.yaml
curl -s $SNIPPET_SOURCE_URL/seichi-onp-k8s-wk-3-network.yaml > $SNIPPET_TARGET_PATH/seichi-onp-k8s-wk-3-network.yaml
qm set 1103 --cicustom "user=$SNIPPET_TARGET_VOLUME:snippets/seichi-onp-k8s-wk-3-user.yaml,network=$SNIPPET_TARGET_VOLUME:snippets/seichi-onp-k8s-wk-3-network.yaml"

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

# end region
