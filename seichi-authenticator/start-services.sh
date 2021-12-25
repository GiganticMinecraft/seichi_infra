#!/bin/bash
set -e

# region configure next reboot

timedatectl set-timezone Asia/Tokyo
echo 'reboot' | at 4:00

# endregion

# region start services

if [ ! -f "/root/seichi_open_servers_configs/.keycloak.env" ]; then
  echo "ERROR: expected an env file at"
  echo "  /root/seichi_open_servers_configs/.keycloak.env"
  echo "Exiting the script..."
  exit 1
fi

docker compose \
  -e KEYCLOAK_ENV_FILE_PATH=/root/seichi_open_servers_configs/.keycloak.env
  -f /root/seichi_open_servers/seichi-authenticator/docker-compose.yml \
  up

# endregion
