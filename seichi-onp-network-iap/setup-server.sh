#!/bin/bash
set -e

# This is an idempotent script that
# - installs all the required toolchains
# - clones the latest revision of seichi_infra to /root/seichi_infra/
# - configures compose-cd to automatically sync services to the remote git repository
# - reboots the server to reinitialize everything

# install docker-ce and docker-compose
bash <(wget -qO- https://raw.githubusercontent.com/GiganticMinecraft/seichi_infra/main/util-scripts/setup/docker-ce-and-compose.sh)

# install toolchains
sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get install git

# region clone the latest revision of seichi_infra

sudo rm -r /root/seichi_infra || true
sudo git clone --depth 1 https://github.com/GiganticMinecraft/seichi_infra.git /root/seichi_infra

# endregion

# region setup compose-cd for continuous deployment

sudo rm -r /root/compose-cd || true
sudo git clone --depth 1 https://github.com/sksat/compose-cd.git /root/compose-cd

# You should input to stdin:
# - search root> /root/seichi_infra/seichi-onp-network-iap
# - git pull user> root
# - Discord webhook URL> ***
sudo /root/compose-cd/compose-cd install

# endregion

echo """
======================================
All setup complete. Rebooting...
======================================
"""

sudo reboot
