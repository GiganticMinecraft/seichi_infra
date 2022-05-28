#!/bin/bash
set -eu

# Cloudflared でオンプレクラスタへのトンネルを張り、
# トンネルが可視となる URL を標準出力に出力するスクリプト。

# トンネル自体のホスト名
tunnel_host="k8s-api.onp-k8s.admin.seichi.click"

# トンネルが可視となるホスト名。
# /terraform/cloudflare_dns_records.tf により、127.0.0.1 に向けられている。
tunnel_entry_host="k8s-api.onp-k8s.admin.local-tunnels.seichi.click"

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
  exit 1
}

function prepare_cloudflared_at () {
  local -r workdir="$1"

  # constants
  local -r cloudflared_release="2022.5.1"
  local -r cloudflared_binary="https://github.com/cloudflare/cloudflared/releases/download/${cloudflared_release}/cloudflared-linux-amd64"

  # download cloudflared
  wget "${cloudflared_binary}" -O "${workdir}/cloudflared"
  chmod 700 "${workdir}/cloudflared"

  echo_to_err "$("${workdir}"/cloudflared --version)"
}

tmp_workdir=$(mktemp -d)
prepare_cloudflared_at "${tmp_workdir}"

logfile=$(mktemp)

tunnel_entry_port="$(pick_free_port)"
tunnel_url="127.0.0.1:${tunnel_entry_port}"

# create tunnel entry on localhost
# close all of stdin/stdout/stderr off and fork
nohup "${tmp_workdir}/cloudflared" access tcp \
  --hostname "${tunnel_host}" \
  --url "${tunnel_url}" \
  0<&- 1>"${logfile}" 2>&1 & disown

echo_to_err "Started a tunnel to ${tunnel_host_name} at ${tunnel_url}"

sleep 3
echo_to_err "Processes after 3 seconds:"
echo_to_err "$(ps -Al)"
echo_to_err ""
echo_to_err "Log of spawned process:"
echo_to_err "$(cat "${logfile}")"

echo "https://${tunnel_entry_host}:${tunnel_entry_port}"
