#!/bin/sh
# クラスタの KBOM (Kubernetes コンポーネントの SBOM) を作り、脆弱性を照合して
# 1 件 1 行の JSON を標準出力に出す。Alloy が Loki に送り、ダッシュボードと
# Loki アラートが {job="trivy-operator/kbom"} を読む。
# 重大度 (TRIVY_SEVERITY) は Trivy が環境変数から直接読む。
set -u

# 文字列を JSON の文字列リテラルにする (Trivy のログはタブ区切りで制御文字も含みうる)
json_str() {
  printf '"%s"' "$(printf '%s' "$1" | tr '\t' ' ' | tr -d '\000-\037' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
}

# Trivy のエラーは "FATAL ...\n  * 原因" のように複数行になるので末尾 5 行をつなげて出す
fail() {
  echo "{\"event\":\"trivy_kbom_scan\",\"success\":false,\"stage\":\"$1\",\"error\":$(json_str "$(tail -5 "$2" | tr '\n' ' ')")}"
  exit 1
}

start=$(date +%s)
trivy k8s \
  --format cyclonedx --disable-node-collector \
  --cache-dir /tmp/trivy --skip-version-check --no-progress --timeout 10m \
  --output /tmp/kbom.json 2>/tmp/kbom.err || fail kbom /tmp/kbom.err
# 照合はクラスタ内の trivy-server に任せる (KBOM の結果は数件なのでサーバーの負荷にならない)。
# DB を Pod ごとに取得すると展開後 1.55GiB の ephemeral storage が要る。
trivy sbom /tmp/kbom.json \
  --scanners vuln --server "${TRIVY_SERVER}" \
  --cache-dir /tmp/trivy --skip-version-check --no-progress --timeout 10m \
  --format template --template @/scripts/kbom.tpl \
  --output /tmp/vulns.jsonl 2>/tmp/sbom.err || fail sbom /tmp/sbom.err
grep -v '^[[:space:]]*$' /tmp/vulns.jsonl
total=$(grep -c '"event":"trivy_kbom_vulnerability"' /tmp/vulns.jsonl)
fixable=$(grep '"event":"trivy_kbom_vulnerability"' /tmp/vulns.jsonl | grep -vc '"fixed_version":""')
# KBOM 内の bom-ref の数 (ルートの metadata.component を含むので、厳密なコンポーネント数より 1 つ多い)
bom_refs=$(grep -o '"bom-ref"' /tmp/kbom.json | wc -l | tr -d ' ')
echo "{\"event\":\"trivy_kbom_scan\",\"success\":true,\"bom_refs\":${bom_refs},\"vulnerabilities\":${total},\"fixable\":${fixable},\"duration_seconds\":$(( $(date +%s) - start ))}"
