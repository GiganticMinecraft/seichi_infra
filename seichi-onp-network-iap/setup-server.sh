#!/bin/bash
set -e

# This is an idempotent script that
# - installs all the required toolchains
# - clones seichi_infra to /root/seichi_infra/
# - start docker services described in
#   ${REPO_ROOT}/seichi-onp-network-iap/services/docker-compose.yml
# - configures compose-cd to automatically sync service definition to the git remote
# - reboots the server to reinitialize everything

# region script constants

# revision at which util scripts are present (main on 2022/03/17)
UTIL_SCRIPTS_REV=GiganticMinecraft/seichi_infra/d457d6dfe71b0542c64c79ed77d3b250601f037d

SYNC_TARGET_REPOSITORY=GiganticMinecraft/seichi_infra
SYNC_TARGET_BRANCH=main

REPOSITORY_LOCAL_DIRECTORY=/root/seichi_infra

# parameters for configuring compose-cd
COMPOSE_CD_RELEASE_TAG=v0.4.2
COMPOSE_CD_SEARCH_ROOT=${REPOSITORY_LOCAL_DIRECTORY}/seichi-onp-network-iap

# endregion

# install toolchains
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get install -y git wget tar

# install docker-ce and docker-compose
bash <(wget -qO- https://raw.githubusercontent.com/${UTIL_SCRIPTS_REV}/util-scripts/setup/docker-ce-and-compose.sh)

# region clone seichi_infra repository on the specified branch

sudo rm -r "${REPOSITORY_LOCAL_DIRECTORY}" || true
sudo git clone \
  --depth 1 \
  --branch ${SYNC_TARGET_BRANCH} \
  "https://github.com/${SYNC_TARGET_REPOSITORY}.git" \
  "${REPOSITORY_LOCAL_DIRECTORY}"
sudo docker compose -f "${COMPOSE_CD_SEARCH_ROOT}/services/docker-compose.yml" up -d

# endregion

# region setup compose-cd for continuous deployment

echo """
=================================================
Installing compose-cd.
You will be prompted to enter Discord webhook URL
to which compose-cd should notify its actions.
=================================================
"""

installation_temp_dir=$(mktemp -d)
cd installation_temp_dir

wget "https://github.com/sksat/compose-cd/releases/download/${COMPOSE_CD_RELEASE_TAG}/compose-cd.tar.gz"
tar -zxvf compose-cd.tar.gz

sudo ./compose-cd install \
  --search-root "${COMPOSE_CD_SEARCH_ROOT}"
  --git-pull-user root

# endregion

echo """
======================================
All setup complete. Rebooting...
======================================
"""

sudo reboot
