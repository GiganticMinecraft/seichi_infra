#!/bin/sh
# chroot /host で実行され、containerd / runc の更新をステージングする。
# ここではダウンロード・検証・宛先ディレクトリへの .staged 配置までを行い、
# 実際の差し替えは kured が drain 完了後 (rebootCommand) に apply.sh で rename
# してから再起動する。稼働中のバイナリには一切触れないため、
# 「drain -> 更新 -> 直後に再起動」の順序が保証され、新旧バージョンの混在期間が生じない。
set -eu
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WANT_CONTAINERD="$1"
WANT_RUNC="$2"

STATE_DIR=/var/lib/node-runtime-updater
PENDING_DIR="$STATE_DIR/pending"

log() { echo "node-runtime-updater: $*"; }

case "$(uname -m)" in
  x86_64) ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  *) log "unsupported architecture: $(uname -m)"; exit 1 ;;
esac

mkdir -p "$PENDING_DIR"
# /tmp が noexec でマウントされる構成でも --version の事前チェックが動くよう /var/lib 配下を使う
workdir=$(mktemp -d "$STATE_DIR/work.XXXXXX")
trap 'rm -rf "$workdir"' EXIT
staged=""

# 宛先と同じディレクトリに .staged を置く。apply.sh は同一 filesystem 内の
# rename をするだけになるため、drain 後の適用がほぼ失敗しない。
# cp が root:root の新規ファイルを作り直後に chmod するため、tarball 側の
# owner / setuid ビット等のメタデータは引き継がれない (常に root:root 0755)
stage_bin() {
  src="$1"
  dst="$2"
  list="$3"
  if [ ! -f "$src" ] || [ -h "$src" ]; then
    log "refusing to stage non-regular file: $src"
    return 1
  fi
  cp "$src" "$dst.node-runtime-updater.staged"
  chmod 0755 "$dst.node-runtime-updater.staged"
  echo "$dst.node-runtime-updater.staged $dst" >> "$list"
}

# pin と一致した (適用済み・pin 巻き戻し等の) コンポーネントの残留ステージングを破棄する。
# これを怠ると、無関係な再起動のタイミングで古いステージングが適用されてしまう
discard_staging() {
  list="$1"
  [ -e "$list" ] || return 0
  while read -r staged_path _; do
    rm -f "$staged_path"
  done < "$list"
  rm -f "$list"
}

# ---- containerd (containerd-shim-runc-v2 / ctr 等も tarball ごと追従する) ----
containerd_bindir=$(dirname "$(command -v containerd || echo /usr/local/bin/containerd)")
containerd_list="$PENDING_DIR/containerd.list"
containerd_staged_bin="$containerd_bindir/containerd.node-runtime-updater.staged"
# 出力例: "containerd github.com/containerd/containerd/v2 v2.3.0 <commit>"
current=$( (containerd --version 2>/dev/null || true) | awk '{print $3}' | sed 's/^v//')
if [ "$current" != "$WANT_CONTAINERD" ]; then
  # ステージ済みなら再ダウンロードしない (毎時の実行で無駄な取得をしないため)
  staged_now=""
  if [ -x "$containerd_staged_bin" ] && [ -e "$containerd_list" ]; then
    staged_now=$( ("$containerd_staged_bin" --version 2>/dev/null || true) | awk '{print $3}' | sed 's/^v//')
  fi
  if [ "$staged_now" = "$WANT_CONTAINERD" ]; then
    log "containerd: ${current:-none} -> $WANT_CONTAINERD (already staged)"
  else
    log "containerd: staging ${current:-none} -> $WANT_CONTAINERD"
    tarball="containerd-${WANT_CONTAINERD}-linux-${ARCH}.tar.gz"
    base_url="https://github.com/containerd/containerd/releases/download/v${WANT_CONTAINERD}"
    curl -fsSL --retry 3 -o "$workdir/$tarball" "$base_url/$tarball"
    curl -fsSL --retry 3 -o "$workdir/$tarball.sha256sum" "$base_url/$tarball.sha256sum"
    (cd "$workdir" && sha256sum -c "$tarball.sha256sum" >/dev/null)
    mkdir "$workdir/containerd"
    tar -xzf "$workdir/$tarball" -C "$workdir/containerd"
    # ステージング前の事前チェック: 新バイナリを実行し、動くこと・
    # 自己申告バージョンが pin と一致することを確認する (壊れたバイナリや arch 違いを弾く)
    chmod 0700 "$workdir/containerd/bin/containerd"
    new_version=$("$workdir/containerd/bin/containerd" --version | awk '{print $3}' | sed 's/^v//')
    if [ "$new_version" != "$WANT_CONTAINERD" ]; then
      log "downloaded containerd reports $new_version, expected $WANT_CONTAINERD; aborting"
      exit 1
    fi
    discard_staging "$containerd_list"
    for f in "$workdir"/containerd/bin/*; do
      stage_bin "$f" "$containerd_bindir/$(basename "$f")" "$containerd_list"
    done
  fi
  staged="$staged containerd=$WANT_CONTAINERD"
else
  discard_staging "$containerd_list"
fi

# ---- runc ----
runc_path="$(command -v runc || echo /usr/local/bin/runc)"
runc_list="$PENDING_DIR/runc.list"
runc_staged_bin="$runc_path.node-runtime-updater.staged"
# 出力例 (1 行目): "runc version 1.4.2"
current=$( (runc --version 2>/dev/null || true) | awk 'NR==1{print $3}')
if [ "$current" != "$WANT_RUNC" ]; then
  staged_now=""
  if [ -x "$runc_staged_bin" ] && [ -e "$runc_list" ]; then
    staged_now=$( ("$runc_staged_bin" --version 2>/dev/null || true) | awk 'NR==1{print $3}')
  fi
  if [ "$staged_now" = "$WANT_RUNC" ]; then
    log "runc: ${current:-none} -> $WANT_RUNC (already staged)"
  else
    log "runc: staging ${current:-none} -> $WANT_RUNC"
    base_url="https://github.com/opencontainers/runc/releases/download/v${WANT_RUNC}"
    curl -fsSL --retry 3 -o "$workdir/runc.$ARCH" "$base_url/runc.$ARCH"
    curl -fsSL --retry 3 -o "$workdir/runc.sha256sum" "$base_url/runc.sha256sum"
    # runc.sha256sum には全アセット分のハッシュが含まれるため対象行のみ検証する
    (cd "$workdir" && grep " [*]\{0,1\}runc\.$ARCH\$" runc.sha256sum | sha256sum -c - >/dev/null)
    # ステージング前の事前チェック (containerd と同様)
    chmod 0700 "$workdir/runc.$ARCH"
    new_version=$("$workdir/runc.$ARCH" --version | awk 'NR==1{print $3}')
    if [ "$new_version" != "$WANT_RUNC" ]; then
      log "downloaded runc reports $new_version, expected $WANT_RUNC; aborting"
      exit 1
    fi
    discard_staging "$runc_list"
    stage_bin "$workdir/runc.$ARCH" "$runc_path" "$runc_list"
  fi
  staged="$staged runc=$WANT_RUNC"
else
  discard_staging "$runc_list"
fi

if [ -n "$staged" ]; then
  # kured が拾う sentinel。drain 後の適用と再起動タイミングの制御は kured に委ねる
  touch /var/run/reboot-required
  log "staged:$staged (apply + reboot will be handled by kured)"
else
  log "containerd $WANT_CONTAINERD / runc $WANT_RUNC: up to date"
fi
