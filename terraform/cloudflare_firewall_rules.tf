resource "cloudflare_filter" "minio_api_requests" {
  zone_id     = local.cloudflare_zone_id
  description = "MinIO API requests"
  expression  = "http.host eq \"minio-console.onp-k8s.admin.seichi.click\""
}

resource "cloudflare_firewall_rule" "bypass_waf_on_minio_api_requests" {
  zone_id     = local.cloudflare_zone_id
  description = "Let MinIO API requests bypass WAF rules"
  filter_id   = cloudflare_filter.minio_api_requests.id
  action      = "bypass"
  products    = toset(["waf"])
}

resource "cloudflare_filter" "phpmyadmin_api_requests" {
  zone_id     = local.cloudflare_zone_id
  description = "phpMyAdmin API requests"
  expression  = "http.host eq \"phpmyadmin.onp-k8s.admin.seichi.click\""
}

resource "cloudflare_firewall_rule" "bypass_waf_on_phpmyadmin_requests" {
  zone_id     = local.cloudflare_zone_id
  description = "Let phpMyAdmin requests bypass WAF rules"
  filter_id   = cloudflare_filter.phpmyadmin_api_requests.id
  action      = "bypass"
  products    = toset(["waf"])
}
