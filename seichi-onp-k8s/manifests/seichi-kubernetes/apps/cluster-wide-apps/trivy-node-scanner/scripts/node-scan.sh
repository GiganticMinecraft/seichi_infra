#!/bin/sh
# ノードの OS パッケージ (dpkg) を trivy rootfs でスキャンし、node-exporter の
# textfile collector が読む .prom ファイルに書き出す。
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
    --db-repository "${TRIVY_DB_REPOSITORY}" \
    --scanners vuln --pkg-types os \
    --severity "${TRIVY_SEVERITY}" --ignore-unfixed \
    --cache-dir /tmp/trivy \
    --format template --template @/scripts/node-scan.tpl \
    --skip-version-check --quiet \
    --timeout 10m \
    --output /tmp/vulns.tsv
  rc=$?
  end=$(date +%s)
  {
    echo '# HELP trivy_node_vulnerabilities Number of fixable vulnerabilities found in a node OS package.'
    echo '# TYPE trivy_node_vulnerabilities gauge'
    if [ "${rc}" -eq 0 ]; then
      # kind: stale-kernel = 稼働中ではない古いカーネルのパッケージ (autoremove で消せる残骸)
      #       running-kernel = 稼働中カーネルのパッケージ (再起動しないと直らない)
      #       package = それ以外
      grep -v '^[[:space:]]*$' /tmp/vulns.tsv | awk -F '\t' -v running="${RUNNING_KERNEL_BASE}" '
        {
          kind = "package"
          if ($1 ~ /^linux-/ && match($1, /[0-9]+\.[0-9]+\.[0-9]+-[0-9]+/)) {
            kind = (substr($1, RSTART, RLENGTH) == running) ? "running-kernel" : "stale-kernel"
          }
          c[$1 "\t" $2 "\t" $3 "\t" kind]++
        }
        END {
          for (k in c) {
            split(k, a, "\t")
            printf "trivy_node_vulnerabilities{pkg_name=\"%s\",installed_version=\"%s\",severity=\"%s\",kind=\"%s\"} %d\n", a[1], a[2], a[3], a[4], c[k]
          }
        }' | sort
    fi
    echo '# HELP trivy_node_running_kernel_info Kernel release the node is running.'
    echo '# TYPE trivy_node_running_kernel_info gauge'
    echo "trivy_node_running_kernel_info{release=\"${RUNNING_KERNEL}\"} 1"
    echo '# HELP trivy_node_scan_success Whether the last node scan succeeded (1) or failed (0).'
    echo '# TYPE trivy_node_scan_success gauge'
    if [ "${rc}" -eq 0 ]; then echo 'trivy_node_scan_success 1'; else echo 'trivy_node_scan_success 0'; fi
    echo '# HELP trivy_node_scan_timestamp_seconds Unix time the last node scan finished.'
    echo '# TYPE trivy_node_scan_timestamp_seconds gauge'
    echo "trivy_node_scan_timestamp_seconds ${end}"
    echo '# HELP trivy_node_scan_duration_seconds Duration of the last node scan in seconds.'
    echo '# TYPE trivy_node_scan_duration_seconds gauge'
    echo "trivy_node_scan_duration_seconds $((end - start))"
  } > "${OUT}.tmp" && mv "${OUT}.tmp" "${OUT}"
  echo "scan finished rc=${rc} duration=$((end - start))s series=$(grep -c '^trivy_node_vulnerabilities{' "${OUT}")"
  rm -f /tmp/vulns.tsv
  sleep "${SCAN_INTERVAL_SECONDS}"
done
