#!/bin/sh
# クラスタの KBOM (Kubernetes コンポーネントの SBOM) を作り、脆弱性を照合して
# 1 件 1 行の JSON を標準出力に出す。Alloy が Loki に送り、ダッシュボードと
# Loki アラートが {job="trivy-operator/kbom"} を読む。
set -u
start=$(date +%s)
if ! trivy k8s \
    --format cyclonedx --disable-node-collector \
    --cache-dir /tmp/trivy --skip-version-check --quiet --timeout 10m \
    --output /tmp/kbom.json 2>/tmp/kbom.err; then
  echo "{\"event\":\"trivy_kbom_scan\",\"success\":false,\"stage\":\"kbom\",\"error\":$(tail -1 /tmp/kbom.err | sed 's/"/\\"/g; s/^/"/; s/$/"/')}"
  exit 1
fi
if ! trivy sbom /tmp/kbom.json \
    --scanners vuln --severity "${TRIVY_SEVERITY}" \
    --db-repository "${TRIVY_DB_REPOSITORY}" \
    --cache-dir /tmp/trivy --skip-version-check --quiet --timeout 10m \
    --format template --template @/scripts/kbom.tpl \
    --output /tmp/vulns.jsonl 2>/tmp/sbom.err; then
  echo "{\"event\":\"trivy_kbom_scan\",\"success\":false,\"stage\":\"sbom\",\"error\":$(tail -1 /tmp/sbom.err | sed 's/"/\\"/g; s/^/"/; s/$/"/')}"
  exit 1
fi
grep -v '^[[:space:]]*$' /tmp/vulns.jsonl
total=$(grep -c '"event":"trivy_kbom_vulnerability"' /tmp/vulns.jsonl)
fixable=$(grep '"event":"trivy_kbom_vulnerability"' /tmp/vulns.jsonl | grep -vc '"fixed_version":""')
components=$(grep -o '"bom-ref"' /tmp/kbom.json | wc -l | tr -d ' ')
echo "{\"event\":\"trivy_kbom_scan\",\"success\":true,\"components\":${components},\"vulnerabilities\":${total},\"fixable\":${fixable},\"duration_seconds\":$(( $(date +%s) - start ))}"
