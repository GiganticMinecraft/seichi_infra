#!/bin/bash
set -e

function echo-bar () {
    echo "======================================"
}

# This is an idempotent script that
# - installs all the required toolchains
# - clones the latest revision of seichi_infra to /root/seichi_infra/
# - configures the server to restart all the services on reboot
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
wget -O docker-compose https://github.com/docker/compose/releases/download/v2.2.2/docker-compose-linux-x86_64
chmod +x docker-compose

sudo mkdir -p /usr/lib/docker/cli-plugins
sudo mv -f docker-compose /usr/lib/docker/cli-plugins

echo-bar
echo "Done installing docker compose. Docker Compose version:"
docker compose version
echo-bar

# endregion

# region clone seichi_infra

sudo rm -r /root/seichi_infra || true
sudo git clone --depth 1 https://github.com/GiganticMinecraft/seichi_infra.git /root/seichi_infra

# endregion

# region configure the systemd service

sudo rm /etc/systemd/system/seichi-onp-network-iap.service
sudo ln -s /root/seichi_infra/seichi-onp-network-iap/seichi-onp-network-iap.service /etc/systemd/system/seichi-onp-network-iap.service
sudo systemctl enable seichi-onp-network-iap

# endregion

# region setup compose-cd for continuous deployment

sudo git clone --depth 1 https://github.com/sksat/compose-cd.git /root/compose-cd
sudo /root/compose-cd/compose-cd install
# plz input stdin:
# - search root> /root/seichi_infra/services
# - git pull user> ***
# - Discord webhook URL> ***
sudo /root/compose-cd/compose-cd update

# endregion

echo-bar
echo "All setup complete. Rebooting..."
echo-bar

sudo reboot
