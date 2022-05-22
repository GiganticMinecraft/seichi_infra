#!/bin/bash

set -e

# Script to spawn a child process to keep cloudflare tunnel alive.

#region constants

tunnel_domain="tunnel.k8s-api.onp-k8s.seichi.click.local"
cloudflared_release="2022.5.1"
cloudflared_binary="https://github.com/cloudflare/cloudflared/releases/download/${cloudflared_release}/cloudflared-linux-amd64"

#endregion

function pick_free_port () {
  # ref. https://stackoverflow.com/a/35338833
  for i in {10000..65535}; do
    # continue if the port accepts some input
    (exec 2>&- echo > "/dev/tcp/localhost/$i") && continue;

    echo "$i"
    return 0
  done

  # no port is open
  return 1
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

# External Program Protocol
# https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source#external-program-protocol
result=$(cat <<EOF
  {
    "host": "${tunnel_domain}:${free_port}"
  }
EOF
)


echo "$result"
