#!/usr/bin/env bash

#region set variables

TARGET_BRANCH=$1
TEMPLATE_VMID=9050
BOOT_IMAGE_TARGET_VOLUME=local-lvm
SNIPPET_TARGET_VOLUME=seichi-prox-backup04
SNIPPET_TARGET_PATH=/mnt/pve/${SNIPPET_TARGET_VOLUME}/snippets
REPOSITORY_RAW_SOURCE_URL="https://raw.githubusercontent.com/GiganticMinecraft/seichi_infra/${TARGET_BRANCH}"
VM_LIST=(
    #vmid #vmname               #cpu #mem  #targetip      #targethost
    "1201 seichi-onp-k8s-wk-mc1 8    65536 192.168.16.152 unchama-sv-prox03"
)

#endregion

# ---

# region create vm from template

for array in "${VM_LIST[@]}"
do
    echo "${array}" | while read -r vmid vmname cpu mem targetip targethost
    do
        # clone from template
        # in clone phase, can't create vm-disk to local volume
        qm clone "${TEMPLATE_VMID}" "${vmid}" --name "${vmname}" --full true --target "${targethost}"
        
        # set compute resources
        ssh -n "${targetip}" qm set "${vmid}" --cores "${cpu}" --memory "${mem}"

        # move vm-disk to local
        ssh -n "${targetip}" qm move-disk "${vmid}" scsi0 "${BOOT_IMAGE_TARGET_VOLUME}" --delete true

        # resize disk (Resize after cloning, because it takes time to clone a large disk)
        ssh -n "${targetip}" qm resize "${vmid}" scsi0 100G

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
  - su - cloudinit -c "curl -s ${REPOSITORY_RAW_SOURCE_URL}/seichi-onp-k8s/cluster-operation/scripts/nodes/k8s-node-join.sh > ~/k8s-node-join.sh"
  - su - cloudinit -c "sudo bash ~/k8s-node-join.sh ${vmname} ${TARGET_BRANCH}"
  # change default shell to bash
  - chsh -s $(which bash) cloudinit
EOF
# ----- #
        # END irregular indent because heredoc
        
        # download snippet for cloud-init(network)
        curl -s "${REPOSITORY_RAW_SOURCE_URL}/seichi-onp-k8s/cluster-operation/snippets/${vmname}-network.yaml" > "${SNIPPET_TARGET_PATH}"/"${vmname}"-network.yaml

        # set snippet to vm
        ssh -n "${targetip}" qm set "${vmid}" --cicustom "user=${SNIPPET_TARGET_VOLUME}:snippets/${vmname}-user.yaml,network=${SNIPPET_TARGET_VOLUME}:snippets/${vmname}-network.yaml"

        # start vm
        ssh -n "${targetip}" qm start "${vmid}"

    done
done

# endregion
