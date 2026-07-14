#!/bin/sh
# chroot /host で実行され、containerd / runc の更新をステージングする。
# ここではダウンロード・検証・宛先ディレクトリへの .staged 配置までを行い、
# 実際の差し替えは kured が drain 完了後 (rebootCommand) に apply.sh で rename
# してから再起動する。稼働中のバイナリには一切触れないため、
# 「drain -> 更新 -> 直後に再起動」の順序が保証され、新旧バージョンの混在期間が生じない。
#
# 収束判定は「インストール済みバージョンの一致」ではなく「pending list が無いこと」で行う。
# apply が途中で失敗した場合 (例: containerd 本体だけ適用され shim が未適用) でも、
# list が残っている限り再ステージ・再適用の対象になり続け、放置されない。
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

# ステージングと target マーカーを破棄する
discard_staging() {
  list="$1"
  rm -f "${list%.list}.target"
  [ -e "$list" ] || return 0
  while read -r staged_path _; do
    rm -f "$staged_path"
  done < "$list"
  rm -f "$list"
}

# list に記載された staged ファイルがすべて存在する場合のみ真 (部分適用後は偽になる)
staging_complete() {
  list="$1"
  [ -e "$list" ] || return 1
  while read -r staged_path _; do
    [ -f "$staged_path" ] || return 1
  done < "$list"
  return 0
}

# ---- containerd (containerd-shim-runc-v2 / ctr 等も tarball ごと追従する) ----
containerd_bindir=$(dirname "$(command -v containerd || echo /usr/local/bin/containerd)")
containerd_list="$PENDING_DIR/containerd.list"
containerd_target_file="$PENDING_DIR/containerd.target"
# 出力例: "containerd github.com/containerd/containerd/v2 v2.3.0 <commit>"
current=$( (containerd --version 2>/dev/null || true) | awk '{print $3}' | sed 's/^v//')

# 現在の pin と異なるバージョン向けの残留ステージングは破棄する (pin の変更・巻き戻し)。
# target が pin と一致するステージングは、部分適用の残りである可能性があるため破棄しない
if [ -e "$containerd_list" ] && [ "$(cat "$containerd_target_file" 2>/dev/null || true)" != "$WANT_CONTAINERD" ]; then
  log "containerd: discarding staging for a different pin"
  discard_staging "$containerd_list"
fi

if [ "$current" != "$WANT_CONTAINERD" ] || [ -e "$containerd_list" ]; then
  if staging_complete "$containerd_list"; then
    # ステージ済み内容は pin と一致 (target 確認済み) かつ全ファイル存在 -> 再ダウンロードしない
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
    # target マーカーは全ファイルのステージ完了後にのみ書く (これがコミットポイント。
    # 途中で中断された場合は target 不一致となり、次回まるごと再ステージされる)
    echo "$WANT_CONTAINERD" > "$containerd_target_file"
  fi
  staged="$staged containerd=$WANT_CONTAINERD"
fi

# ---- runc ----
runc_path="$(command -v runc || echo /usr/local/bin/runc)"
runc_list="$PENDING_DIR/runc.list"
runc_target_file="$PENDING_DIR/runc.target"
# 出力例 (1 行目): "runc version 1.4.2"
current=$( (runc --version 2>/dev/null || true) | awk 'NR==1{print $3}')

if [ -e "$runc_list" ] && [ "$(cat "$runc_target_file" 2>/dev/null || true)" != "$WANT_RUNC" ]; then
  log "runc: discarding staging for a different pin"
  discard_staging "$runc_list"
fi

if [ "$current" != "$WANT_RUNC" ] || [ -e "$runc_list" ]; then
  if staging_complete "$runc_list"; then
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
    echo "$WANT_RUNC" > "$runc_target_file"
  fi
  staged="$staged runc=$WANT_RUNC"
fi

if [ -n "$staged" ]; then
  # kured が拾う sentinel。drain 後の適用と再起動タイミングの制御は kured に委ねる
  touch /var/run/reboot-required
  log "staged:$staged (apply + reboot will be handled by kured)"
else
  log "containerd $WANT_CONTAINERD / runc $WANT_RUNC: up to date"
fi
