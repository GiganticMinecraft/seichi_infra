#!/bin/bash
set -e

function echo-bar () {
    echo "======================================"
}

# This is an idempotent script that
# - installs all the required toolchains
# - configures the server to
#   - reboot at 16:00 AM
#   - restart all the services on reboot
# - reboots the server to reinitialize everything

sudo apt-get -y update && sudo apt-get -y upgrade

# region install misc toolchains

# required for docker (https://docs.docker.com/engine/install/ubuntu/)
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# endregion

# region install docker (see https://docs.docker.com/engine/install/ubuntu/)

sudo apt-get remove docker docker-engine docker.io containerd runc || true

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get -y install docker-ce docker-ce-cli containerd.io

echo-bar
echo "done installing docker-ce. docker --version output:"
docker --version
echo-bar

# endregion

echo-bar
echo "all setup complete. rebooting..."
echo-bar

sudo reboot
