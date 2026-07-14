#!/bin/sh
# kured の rebootCommand から drain 完了後・再起動直前に呼ばれ、host-update.sh が
# ステージした containerd / runc バイナリを rename で本適用する。ステージングが
# 無ければ何もしない。rename は同一 filesystem 内なので atomic で、実行中の
# プロセス (直後の再起動で入れ替わる) にも影響しない。
set -eu

PENDING_DIR=/var/lib/node-runtime-updater/pending
[ -d "$PENDING_DIR" ] || exit 0

for list in "$PENDING_DIR"/*.list; do
  # glob がマッチしなかった場合はパターンがそのまま残るためスキップ
  [ -e "$list" ] || continue
  while read -r staged_path final_path; do
    if [ -f "$staged_path" ]; then
      mv -f "$staged_path" "$final_path"
    fi
  done < "$list"
  rm -f "$list"
  echo "node-runtime-updater: applied staged $(basename "$list" .list)"
done
