#!/bin/sh
# コンテナ側エントリポイント。ホスト側スクリプト (host-update.sh) を chroot 越しに定期実行する。
set -eu

: "${CONTAINERD_VERSION:?}" "${RUNC_VERSION:?}"
INTERVAL="${CHECK_INTERVAL_SECONDS:-3600}"

while true; do
  # ホストの /tmp は world-writable なので、固定名ではなく mktemp (O_EXCL) で安全に配置する
  script_path=$(chroot /host mktemp /tmp/node-runtime-updater.XXXXXX)
  cp /scripts/host-update.sh "/host${script_path}"
  if ! chroot /host /bin/sh "$script_path" "$CONTAINERD_VERSION" "$RUNC_VERSION"; then
    echo "node-runtime-updater: update check failed; retry in ${INTERVAL}s" >&2
  fi
  rm -f "/host${script_path}"
  sleep "$INTERVAL"
done
