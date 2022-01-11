#!/bin/bash
set -e

# This is an idempotent script that installs docker-ce and docker-compose

function echo-bar () {
    echo "======================================"
}

# region version constants

DOCKER_COMPOSE_VERSION=v2.2.2

# endregion

# region install misc toolchains

sudo apt-get -y update

# required for docker (https://docs.docker.com/engine/install/ubuntu/)
sudo apt-get -y install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo apt-get -y upgrade

# endregion

# region install docker (see https://docs.docker.com/engine/install/ubuntu/)

sudo apt-get remove docker docker-engine docker.io containerd runc || true

sudo rm /usr/share/keyrings/docker-archive-keyring.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get -y install docker-ce docker-ce-cli containerd.io

echo-bar
echo "Done installing docker-ce. Docker version:"
docker --version
echo-bar

# endregion

# region install docker compose (see https://github.com/docker/compose/tree/381df200105f902db9d9e7f109c19bbed58302cd#linux)

cd ~
wget -O docker-compose "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64"
chmod +x docker-compose

sudo mkdir -p /usr/lib/docker/cli-plugins
sudo mv -f docker-compose /usr/lib/docker/cli-plugins

echo-bar
echo "Done installing docker compose. Docker Compose version:"
docker compose version
echo-bar

# endregion
