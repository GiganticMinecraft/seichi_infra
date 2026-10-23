#!/bin/sh
# ノードの OS パッケージ (dpkg) を trivy rootfs でスキャンし、node-exporter の
# textfile collector が読む .prom ファイルに書き出す。
# DB の取得先 (TRIVY_DB_REPOSITORY) と重大度 (TRIVY_SEVERITY) は Trivy が環境変数から直接読む。
set -u

OUT_DIR=/textfile
OUT="${OUT_DIR}/trivy_node.prom"
# コンテナはホストのカーネルを共有するので uname -r は稼働中のカーネル (例: 7.0.0-38-generic)
RUNNING_KERNEL="$(uname -r)"
RUNNING_KERNEL_BASE="$(echo "${RUNNING_KERNEL}" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+-[0-9]+).*/\1/')"

# 全ノードが同時に DB を取りに行かないよう、初回だけ開始時刻をずらす
jitter=$(( $(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % ${SCAN_JITTER_SECONDS} ))
echo "first scan in ${jitter}s (running kernel ${RUNNING_KERNEL})"
sleep "${jitter}"

while true; do
  start=$(date +%s)
  trivy rootfs /host \
    --scanners vuln --pkg-types os --ignore-unfixed \
    --cache-dir /tmp/trivy \
    --format template --template @/scripts/node-scan.tpl \
    --skip-version-check --quiet \
    --timeout 10m \
    --output /tmp/vulns.tsv
  rc=$?
  end=$(date +%s)
  if [ "${rc}" -eq 0 ]; then
    # kind: running-kernel = 稼働中カーネルのパッケージ (更新して再起動しないと直らない)
    #       newer-kernel   = 稼働中より新しいカーネルのパッケージ (インストール済みで再起動待ち)
    #       stale-kernel   = 稼働中より古いカーネルの残骸 (apt autoremove --purge で消せる)
    #       package        = それ以外
    grep -v '^[[:space:]]*$' /tmp/vulns.tsv | awk -F '\t' -v running="${RUNNING_KERNEL_BASE}" '
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
    # 失敗していることは trivy_node_scan_success=0 と TrivyNodeScanFailing で分かる。
    grep '^trivy_node_vulnerabilities{' "${OUT}" > /tmp/vulns.prom 2>/dev/null || : > /tmp/vulns.prom
  fi
  {
    echo '# HELP trivy_node_vulnerabilities Number of fixable vulnerabilities found in a node OS package (last successful scan).'
    echo '# TYPE trivy_node_vulnerabilities gauge'
    cat /tmp/vulns.prom
    echo '# HELP trivy_node_scan_success Whether the last node scan succeeded (1) or failed (0).'
    echo '# TYPE trivy_node_scan_success gauge'
    if [ "${rc}" -eq 0 ]; then echo 'trivy_node_scan_success 1'; else echo 'trivy_node_scan_success 0'; fi
    echo '# HELP trivy_node_scan_timestamp_seconds Unix time the last node scan finished.'
    echo '# TYPE trivy_node_scan_timestamp_seconds gauge'
    echo "trivy_node_scan_timestamp_seconds ${end}"
  } > "${OUT}.tmp" && mv "${OUT}.tmp" "${OUT}"
  echo "scan finished rc=${rc} duration=$((end - start))s series=$(wc -l < /tmp/vulns.prom | tr -d ' ')"
  rm -f /tmp/vulns.tsv /tmp/vulns.prom
  sleep "${SCAN_INTERVAL_SECONDS}"
done
