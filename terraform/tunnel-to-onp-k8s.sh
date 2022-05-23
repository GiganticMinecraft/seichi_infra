#!/bin/bash

set -e

# Script to spawn a child process to keep cloudflare tunnel alive.

#region constants

cloudflared_release="2022.5.1"
cloudflared_binary="https://github.com/cloudflare/cloudflared/releases/download/${cloudflared_release}/cloudflared-linux-amd64"

# Domain at which the api endpoint should be visible
tunnel_domain="tunnel.k8s-api.onp-k8s.seichi.click.local"

# Domain at which the tunnel connection can be established
tunnel_host_name="k8s-api.onp-k8s.admin.seichi.click"

#endregion

#region misc

function echo_to_err () {
  echo "$1" >&2;
}

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

#endregion

function reroute_tunnel_domain_to_localhost () {
  sudo -- sh -c "echo \"127.0.0.1  ${tunnel_domain}\" >> /etc/hosts"
}

tmp_workdir=$(mktemp -d)

# download cloudflared
wget "${cloudflared_binary}" -O "${tmp_workdir}/cloudflared"
chmod 700 "${tmp_workdir}/cloudflared"

free_port=$(pick_free_port)

echo_to_err "$(cloudflared --version)"
echo_to_err "Using port: ${free_port}"

# create tunnel entry on localhost
nohup "${tmp_workdir}/cloudflared" access tcp \
  --hostname "${tunnel_host_name}" \
  --url "localhost:${free_port}" &

echo_to_err "Started a tunnel to ${tunnel_host_name} at localhost:${free_port}"

reroute_tunnel_domain_to_localhost

echo_to_err "Rerouted ${tunnel_domain} to 127.0.0.1"

# External Program Protocol
# https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source#external-program-protocol
result=$(cat <<EOF
  {
    "host": "${tunnel_domain}:${free_port}"
  }
EOF
)


echo "$result"
