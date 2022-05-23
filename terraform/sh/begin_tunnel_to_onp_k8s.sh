#!/bin/bash
set -e

# Script to spawn a child process to keep cloudflare tunnel alive.

#region query

# Domain at which the tunnel connection can be established
tunnel_host_name="$1"

# Address at which the tunnel should be binded
tunnel_url="$2"

#endregion

#region constants

cloudflared_release="2022.5.1"
cloudflared_binary="https://github.com/cloudflare/cloudflared/releases/download/${cloudflared_release}/cloudflared-linux-amd64"

#endregion

#region misc

function echo_to_err () {
  echo "$1" >&2;
}

#endregion

tmp_workdir=$(mktemp -d)
logfile=$(mktemp)

# download cloudflared
wget "${cloudflared_binary}" -O "${tmp_workdir}/cloudflared"
chmod 700 "${tmp_workdir}/cloudflared"

echo_to_err "$("${tmp_workdir}"/cloudflared --version)"

# create tunnel entry on localhost
# close all of stdin/stdout/stderr off and fork
nohup "${tmp_workdir}/cloudflared" access tcp \
  --hostname "${tunnel_host_name}" \
  --url "${tunnel_url}" \
  0<&- 1>&logfile 2>&logfile &
  
disown

echo_to_err "Started a tunnel to ${tunnel_host_name} at ${tunnel_url}"

sleep 3
echo_to_err "Processes after 3 seconds:"
echo_to_err "$(ps -al)"
echo_to_err ""
echo_to_err "Log of spawned process:"
echo_to_err "$(cat "${logfile}")"

# External Program Protocol
# https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source#external-program-protocol
result=$(cat <<EOF
  {}
EOF
)


echo "$result"
