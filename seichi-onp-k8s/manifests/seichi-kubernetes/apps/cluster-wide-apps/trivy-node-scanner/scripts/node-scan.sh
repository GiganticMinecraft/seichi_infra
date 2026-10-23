#!/bin/sh
# ノードの OS パッケージ (dpkg) を trivy rootfs でスキャンし、node-exporter の
# textfile collector が読む .prom ファイルに書き出す。
# DB の取得先 (TRIVY_DB_REPOSITORY) と重大度 (TRIVY_SEVERITY) は Trivy が環境変数から直接読む。
set -u

# PID 1 の sh は SIGTERM を無視するので、明示的に終了する (sleep は wait で待つ)
trap 'exit 0' TERM INT

OUT_DIR=/textfile
OUT="${OUT_DIR}/trivy_node.prom"
# コンテナはホストのカーネルを共有するので uname -r は稼働中のカーネル (例: 7.0.0-38-generic)
RUNNING_KERNEL="$(uname -r)"
RUNNING_KERNEL_BASE="$(echo "${RUNNING_KERNEL}" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+-[0-9]+).*/\1/')"

pause() {
  sleep "$1" &
  wait $!
}

# 全ノードが同時に DB を取りに行かないよう、初回だけ開始時刻をずらす (0 ならずらさない)
jitter=0
if [ "${SCAN_JITTER_SECONDS:-0}" -gt 0 ] 2>/dev/null; then
  jitter=$(( $(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % SCAN_JITTER_SECONDS ))
fi
echo "first scan in ${jitter}s (running kernel ${RUNNING_KERNEL})"
pause "${jitter}"

while true; do
  start=$(date +%s)
  # 試行の開始時点で success=0 にしておく。trivy ごとコンテナが OOMKilled / evict されると
  # 結果を書き直す機会が無いため、前回の success=1 が残って失敗に気付けなくなる。
  if [ -f "${OUT}" ]; then
    sed 's/^trivy_node_scan_success 1$/trivy_node_scan_success 0/' "${OUT}" > "${OUT}.tmp" && mv "${OUT}.tmp" "${OUT}"
  fi
  # trivy をバックグラウンドで動かして wait する (フォアグラウンドだと SIGTERM の trap が終わるまで動かない)
  trivy rootfs /host \
    --scanners vuln --pkg-types os --ignore-unfixed \
    --cache-dir /tmp/trivy \
    --format template --template @/scripts/node-scan.tpl \
    --skip-version-check --no-progress \
    --timeout 10m \
    --output /tmp/vulns.tsv &
  wait $!
  rc=$?
  # DB は数時間おきに更新されるので次回 (24h 後) には使えない。ノードの ephemeral storage を
  # 1.55GiB 占有し続けないよう毎回消す。
  rm -rf /tmp/trivy
  # Trivy は OS を判定できないと 0 件のまま exit 0 する。os-pkgs の結果が無ければ失敗扱いにする
  # (lsb-release が読めないなどで 0 件 = 問題なしに見えるのを防ぐ)。
  if [ "${rc}" -eq 0 ] && ! grep -q "$(printf '^__result__\tos-pkgs\t')" /tmp/vulns.tsv; then
    echo "OS packages were not detected (check the os-release / lsb-release / dpkg mounts)"
    rc=3
  fi
  end=$(date +%s)
  last_success=$(sed -n 's/^trivy_node_last_success_timestamp_seconds //p' "${OUT}" 2>/dev/null)
  if [ "${rc}" -eq 0 ]; then
    last_success="${end}"
    # kind: running-kernel = 稼働中カーネルのパッケージ (更新して再起動しないと直らない)
    #       newer-kernel   = 稼働中より新しいカーネルのパッケージ (インストール済みで再起動待ち)
    #       stale-kernel   = 稼働中より古いカーネルの残骸 (apt autoremove --purge で消せる)
    #       package        = それ以外
    grep -v '^[[:space:]]*$' /tmp/vulns.tsv | grep -v '^__result__' | awk -F '\t' -v running="${RUNNING_KERNEL_BASE}" '
      # "7.0.0-38" 形式を数値の配列にして比較する (-1: a<b, 0: a==b, 1: a>b)
      function vcmp(a, b,    x, y, n, i) {
        gsub(/-/, ".", a); gsub(/-/, ".", b)
        n = split(a, x, "."); split(b, y, ".")
        for (i = 1; i <= n; i++) {
          if (x[i] + 0 < y[i] + 0) return -1
          if (x[i] + 0 > y[i] + 0) return 1
        }
        return 0
      }
      {
        kind = "package"
        if ($1 ~ /^linux-/ && match($1, /[0-9]+\.[0-9]+\.[0-9]+-[0-9]+/)) {
          c = vcmp(substr($1, RSTART, RLENGTH), running)
          kind = (c == 0) ? "running-kernel" : (c > 0 ? "newer-kernel" : "stale-kernel")
        }
        count[$1 "\t" $2 "\t" $3 "\t" kind]++
      }
      END {
        for (k in count) {
          split(k, a, "\t")
          printf "trivy_node_vulnerabilities{pkg_name=\"%s\",installed_version=\"%s\",severity=\"%s\",kind=\"%s\"} %d\n", a[1], a[2], a[3], a[4], count[k]
        }
      }' | sort > /tmp/vulns.prom
  else
    # 失敗したときは前回成功時の結果を残す (消すとダッシュボード上で 0 件 = 問題なしに見える)。
    # 古さは trivy_node_last_success_timestamp_seconds で分かる。
    grep '^trivy_node_vulnerabilities{' "${OUT}" > /tmp/vulns.prom 2>/dev/null || : > /tmp/vulns.prom
  fi
  {
    echo '# HELP trivy_node_vulnerabilities Number of fixable vulnerabilities found in a node OS package (last successful scan).'
    echo '# TYPE trivy_node_vulnerabilities gauge'
    cat /tmp/vulns.prom
    echo '# HELP trivy_node_scan_success Whether the last node scan attempt succeeded (1) or failed (0).'
    echo '# TYPE trivy_node_scan_success gauge'
    if [ "${rc}" -eq 0 ]; then echo 'trivy_node_scan_success 1'; else echo 'trivy_node_scan_success 0'; fi
    echo '# HELP trivy_node_scan_timestamp_seconds Unix time the last node scan attempt finished.'
    echo '# TYPE trivy_node_scan_timestamp_seconds gauge'
    echo "trivy_node_scan_timestamp_seconds ${end}"
    if [ -n "${last_success}" ]; then
      echo '# HELP trivy_node_last_success_timestamp_seconds Unix time of the last successful node scan (the one trivy_node_vulnerabilities comes from).'
      echo '# TYPE trivy_node_last_success_timestamp_seconds gauge'
      echo "trivy_node_last_success_timestamp_seconds ${last_success}"
    fi
  } > "${OUT}.tmp" && mv "${OUT}.tmp" "${OUT}"
  echo "scan finished rc=${rc} duration=$((end - start))s series=$(wc -l < /tmp/vulns.prom | tr -d ' ')"
  rm -f /tmp/vulns.tsv /tmp/vulns.prom
  # 失敗 (DB 取得の一時的な失敗など) は 24h 待たずに再試行する
  if [ "${rc}" -eq 0 ]; then pause "${SCAN_INTERVAL_SECONDS}"; else pause "${SCAN_RETRY_SECONDS:-3600}"; fi
done
