#!/bin/bash

# Argo Tunnel の作成に使える cert.pem (API key) を取得し、標準出力に出力する。

# region 定数の定義

# cert.pem がダウンロードされるパス
cert_pem_downloaded_location="${HOME}/.cloudflared/cert.pem"

# 利用する cloudflared のバージョン等
cloudflared_release="2022.5.1"
cloudflared_binary="https://github.com/cloudflare/cloudflared/releases/download/${cloudflared_release}/cloudflared-linux-amd64"

# endregion

workdir=$(mktemp -d)

function preempt_cert_pem_and () {
  local -r command="$1"

  if [ -f "${cert_pem_downloaded_location}" ]; then
    mv "${cert_pem_downloaded_location}" "${workdir}/cert.pem.old"
  fi

  ("${command}")
  local -r command_result="$?"

  if [ -f "${workdir}/cert.pem.old" ]; then
    mv "${workdir}/cert.pem.old" "${cert_pem_downloaded_location}"
  fi

  if (( "${command_result}" == 0 )); then
    return 0
  else
    echo "Command failed: ${command}" 1>&2
    exit 1
  fi
}

function download_and_print_cert_pem () {
  # 標準出力: cert.pemのダウンロードに成功した場合、cert.pemの内容。
  #           ダウンロードに失敗した場合、non-zero codeでexitする。
  # 事前条件: ${cert_pem_downloaded_location} にファイルが存在しない
  # 事後条件: ${cert_pem_downloaded_location} にファイルが存在しない
  if [ -f "${cert_pem_downloaded_location}" ]; then
    exit 1
  fi

  "${workdir}/cloudflared" login 1>&2
  local -r command_result="$?"

  if (( "${command_result}" != 0 )); then
    echo "cert.pem download failed!" 1>&2
    exit 1
  else
    cat "${cert_pem_downloaded_location}"
    rm "${cert_pem_downloaded_location}"
    return 0
  fi
}

# cloudflared をダウンロードする
wget "${cloudflared_binary}" -O "${workdir}/cloudflared" 1>&2
chmod +x "${workdir}/cloudflared" 1>&2

# cert.pem をダウンロードし、標準出力に内容を出力する。
preempt_cert_pem_and download_and_print_cert_pem
