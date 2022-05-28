#!/bin/bash
set -eu

script_dir=$(dirname -- "$(rreadlink "$0")")

onp_k8s_server_url="$(bash "${script_dir}/open-tunnel-to-onp-k8s.sh")"

echo "TF_VAR_onp_k8s_server_url=${onp_k8s_server_url}" >> "$GITHUB_ENV"
