#!/bin/sh
# クラスタの KBOM (Kubernetes コンポーネントの SBOM) を作り、脆弱性を照合して
# 1 件 1 行の JSON を標準出力に出す。Alloy が Loki に送り、ダッシュボードと
# Loki アラートが {job="trivy-operator/kbom"} を読む。
# DB の取得先 (TRIVY_DB_REPOSITORY) と重大度 (TRIVY_SEVERITY) は Trivy が環境変数から直接読む。
set -u

# 文字列を JSON の文字列リテラルにする (Trivy のログはタブ区切りで制御文字も含みうる)
json_str() {
  printf '"%s"' "$(printf '%s' "$1" | tr '\t' ' ' | tr -d '\000-\037' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
}

fail() {
  echo "{\"event\":\"trivy_kbom_scan\",\"success\":false,\"stage\":\"$1\",\"error\":$(json_str "$(tail -1 "$2")")}"
  exit 1
}

start=$(date +%s)
trivy k8s \
  --format cyclonedx --disable-node-collector \
  --cache-dir /tmp/trivy --skip-version-check --quiet --timeout 10m \
  --output /tmp/kbom.json 2>/tmp/kbom.err || fail kbom /tmp/kbom.err
trivy sbom /tmp/kbom.json \
  --scanners vuln \
  --cache-dir /tmp/trivy --skip-version-check --quiet --timeout 10m \
  --format template --template @/scripts/kbom.tpl \
  --output /tmp/vulns.jsonl 2>/tmp/sbom.err || fail sbom /tmp/sbom.err
grep -v '^[[:space:]]*$' /tmp/vulns.jsonl
total=$(grep -c '"event":"trivy_kbom_vulnerability"' /tmp/vulns.jsonl)
fixable=$(grep '"event":"trivy_kbom_vulnerability"' /tmp/vulns.jsonl | grep -vc '"fixed_version":""')
components=$(grep -o '"bom-ref"' /tmp/kbom.json | wc -l | tr -d ' ')
echo "{\"event\":\"trivy_kbom_scan\",\"success\":true,\"components\":${components},\"vulnerabilities\":${total},\"fixable\":${fixable},\"duration_seconds\":$(( $(date +%s) - start ))}"
