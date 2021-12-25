#!/bin/bash
set -e

function echo-bar () {
    echo "======================================"
}

# This is an idempotent script that
# - installs all the required toolchains
# - clones the latest revision of seichi_open_servers to /root/seichi_open_servers/
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

# region clone seichi_open_servers

sudo rm -r /root/seichi_open_servers
sudo git clone --depth 1 git@github.com:GiganticMinecraft/seichi_servers.git /root/seichi_open_servers

# endregion

# region configure the systemd service

ln -s /root/seichi_open_servers/seichi-authenticator/seichi-authenticator.service /etc/systemd/system/seichi-authenticator.service
systemctl enable seichi-authenticator

# endregion

echo-bar
echo "All setup complete. Rebooting..."
echo-bar

sudo reboot
