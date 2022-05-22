#!/bin/bash

# Script to spawn a child process to keep cloudflare tunnel alive.

#region constants

tunnel_domain="tunnel.k8s-api.onp-k8s.seichi.click.local"
cloudflared_release="2022.5.1"
cloudflared_binary="https://github.com/cloudflare/cloudflared/releases/download/${cloudflared_release}/cloudflared-linux-amd64"

#endregion

function pick_free_port () {
  # ref. https://stackoverflow.com/a/1365284
  cat <<EOF | python3
import socket
sock = socket.socket()
sock.bind(("", 0))
print(str(s.getsockname()[1]))
s.close()
EOF
}

function reroute_tunnel_domain_to_localhost () {
  echo "127.0.0.1  ${tunnel_domain}" >> /etc/hosts
}

tmp_workdir=$(mktemp -d)

# download cloudflared
wget \
  "${cloudflared_binary}" \
  -O "${tmp_workdir}/cloudflared"

free_port=$(pick_free_port)

# create tunnel entry on localhost
nohup "${tmp_workdir}/cloudflared" access tcp \
  --hostname "k8s-api.onp-k8s.admin.seichi.click" \
  --url "localhost:${free_port}" &

reroute_tunnel_domain_to_localhost

echo <<EOF
  {
    host: "${tunnel_domain}:${free_port}"
  }
EOF
