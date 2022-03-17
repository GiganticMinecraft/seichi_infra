#!/bin/bash
set -e

# revision at which util scripts are present (main on 2022/03/17)
UTIL_SCRIPTS_REV=GiganticMinecraft/seichi_infra/d457d6dfe71b0542c64c79ed77d3b250601f037d

SYNC_TARGET_REPOSITORY=GiganticMinecraft/seichi_infra
SYNC_TARGET_BRANCH=main

# variables read by `compose-cd install`
export SEARCH_ROOT=/root/seichi_infra/seichi-onp-network-iap
export GIT_PULL_USER=root
export -n DISCORD_WEBHOOK

# This is an idempotent script that
# - installs all the required toolchains
# - clones the latest revision of seichi_infra to /root/seichi_infra/
# - configures compose-cd to automatically sync services to the remote git repository
# - reboots the server to reinitialize everything

# install docker-ce and docker-compose
bash <(wget -qO- https://raw.githubusercontent.com/${UTIL_SCRIPTS_REV}/util-scripts/setup/docker-ce-and-compose.sh)

# install toolchains
sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get install git

# region clone the latest revision of seichi_infra

sudo rm -r /root/seichi_infra || true
sudo git clone --depth 1 --branch ${SYNC_TARGET_BRANCH} "https://github.com/${SYNC_TARGET_REPOSITORY}.git" /root/seichi_infra
sudo docker compose -f /root/seichi_infra/seichi-onp-network-iap/services/docker-compose.yml up -d

# endregion

# region setup compose-cd for continuous deployment

sudo rm -r ~/install-compose-cd || true
sudo git clone --depth 1 https://github.com/GiganticMinecraft/compose-cd.git ~/install-compose-cd
cd ~/install-compose-cd

echo """
======================================
Installing compose-cd.
You should input to stdin:
- Discord webhook URL> ***
======================================
"""
sudo ./compose-cd install

# endregion

echo """
======================================
All setup complete. Rebooting...
======================================
"""

sudo reboot
