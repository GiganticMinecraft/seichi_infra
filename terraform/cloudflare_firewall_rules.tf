resource "cloudflare_ruleset" "waf_bypass_rules" {
  zone_id     = local.cloudflare_zone_id
  name        = "WAF Bypass Rules"
  description = "WAFルールをバイパスするカスタムファイアウォールルール"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules {
    action      = "skip"
    expression  = "http.host eq \"minio-console.onp-k8s.admin.seichi.click\""
    description = "Let MinIO API requests bypass WAF rules"
    action_parameters {
      products = ["waf"]
    }
    enabled = true
  }

  rules {
    action      = "skip"
    expression  = "http.host eq \"phpmyadmin.onp-k8s.admin.seichi.click\""
    description = "Let phpMyAdmin requests bypass WAF rules"
    action_parameters {
      products = ["waf"]
    }
    enabled = true
  }
}
