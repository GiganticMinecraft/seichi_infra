#!/bin/sh
# chroot /host で実行され、containerd / runc を引数で渡されたバージョンへ揃える。
# バイナリは rename(2) で差し替えるため実行中のプロセスには影響せず、実際の切り替えは
# /var/run/reboot-required を検知した kured の drain + 再起動 (05:00-07:00 JST) に委ねる。
set -eu
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WANT_CONTAINERD="$1"
WANT_RUNC="$2"
ARCH=amd64

log() { echo "node-runtime-updater: $*"; }

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
updated=""

# rename は atomic なので ETXTBSY を踏まずに実行中のバイナリを差し替えられる。
# cp が root:root の新規ファイルを作り直後に chmod するため、tarball 側の
# owner / setuid ビット等のメタデータは最終状態に引き継がれない (常に root:root 0755)
install_bin() {
  src="$1"
  dst="$2"
  if [ ! -f "$src" ] || [ -h "$src" ]; then
    log "refusing to install non-regular file: $src"
    return 1
  fi
  cp "$src" "$dst.node-runtime-updater.new"
  chmod 0755 "$dst.node-runtime-updater.new"
  mv -f "$dst.node-runtime-updater.new" "$dst"
}

# 出力例: "containerd github.com/containerd/containerd/v2 v2.3.0 <commit>"
current=$( (containerd --version 2>/dev/null || true) | awk '{print $3}' | sed 's/^v//')
if [ "$current" != "$WANT_CONTAINERD" ]; then
  log "containerd: ${current:-none} -> $WANT_CONTAINERD"
  tarball="containerd-${WANT_CONTAINERD}-linux-${ARCH}.tar.gz"
  base_url="https://github.com/containerd/containerd/releases/download/v${WANT_CONTAINERD}"
  curl -fsSL --retry 3 -o "$workdir/$tarball" "$base_url/$tarball"
  curl -fsSL --retry 3 -o "$workdir/$tarball.sha256sum" "$base_url/$tarball.sha256sum"
  (cd "$workdir" && sha256sum -c "$tarball.sha256sum" >/dev/null)
  mkdir "$workdir/containerd"
  tar -xzf "$workdir/$tarball" -C "$workdir/containerd"
  # スワップ前の事前チェック: 新バイナリを workdir 内で実行し、動くこと・
  # 自己申告バージョンが pin と一致することを確認する (壊れたバイナリや arch 違いを弾く)
  chmod 0700 "$workdir/containerd/bin/containerd"
  new_version=$("$workdir/containerd/bin/containerd" --version | awk '{print $3}' | sed 's/^v//')
  if [ "$new_version" != "$WANT_CONTAINERD" ]; then
    log "downloaded containerd reports $new_version, expected $WANT_CONTAINERD; aborting"
    exit 1
  fi
  bindir=$(dirname "$(command -v containerd || echo /usr/local/bin/containerd)")
  for f in "$workdir"/containerd/bin/*; do
    install_bin "$f" "$bindir/$(basename "$f")"
  done
  updated="$updated containerd=$WANT_CONTAINERD"
fi

# 出力例 (1 行目): "runc version 1.4.2"
current=$( (runc --version 2>/dev/null || true) | awk 'NR==1{print $3}')
if [ "$current" != "$WANT_RUNC" ]; then
  log "runc: ${current:-none} -> $WANT_RUNC"
  base_url="https://github.com/opencontainers/runc/releases/download/v${WANT_RUNC}"
  curl -fsSL --retry 3 -o "$workdir/runc.$ARCH" "$base_url/runc.$ARCH"
  curl -fsSL --retry 3 -o "$workdir/runc.sha256sum" "$base_url/runc.sha256sum"
  # runc.sha256sum には全アセット分のハッシュが含まれるため対象行のみ検証する
  (cd "$workdir" && grep " [*]\{0,1\}runc\.$ARCH\$" runc.sha256sum | sha256sum -c - >/dev/null)
  # スワップ前の事前チェック (containerd と同様)
  chmod 0700 "$workdir/runc.$ARCH"
  new_version=$("$workdir/runc.$ARCH" --version | awk 'NR==1{print $3}')
  if [ "$new_version" != "$WANT_RUNC" ]; then
    log "downloaded runc reports $new_version, expected $WANT_RUNC; aborting"
    exit 1
  fi
  install_bin "$workdir/runc.$ARCH" "$(command -v runc || echo /usr/local/bin/runc)"
  updated="$updated runc=$WANT_RUNC"
fi

if [ -n "$updated" ]; then
  # kured が拾う sentinel。再起動タイミングの制御 (時間帯・並列数・アラートゲート) は kured に委ねる
  touch /var/run/reboot-required
  log "updated:$updated (reboot will be handled by kured)"
else
  log "containerd $WANT_CONTAINERD / runc $WANT_RUNC: up to date"
fi
