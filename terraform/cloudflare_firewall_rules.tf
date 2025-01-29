resource "cloudflare_ruleset" "minio_api_requests" {
  zone_id     = local.cloudflare_zone_id
  kind        = "zone"
  name        = "MinIO API requests"
  description = "MinIO API requests"
  phase       = "http_request_firewall_managed"
  rules {
    action     = "bypass"
    expression = "(http.host eq \"minio-console.onp-k8s.admin.seichi.click\")"
    action_parameters {
      products = toset(["waf"])
    }
  }
}

resource "cloudflare_ruleset" "phpmyadmin_api_requests" {
  zone_id     = local.cloudflare_zone_id
  kind        = "zone"
  name        = "phpMyAdmin API requests"
  description = "phpMyAdmin API requests"
  phase       = "http_request_firewall_managed"
  rules {
    action     = "bypass"
    expression = "(http.host eq \"phpmyadmin.onp-k8s.admin.seichi.click\")"
    action_parameters {
      products = toset(["waf"])
    }
  }
}
