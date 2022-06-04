# ユーザーが直接アクセスする経路を保護する certificate pack。
resource "cloudflare_certificate_pack" "advanced_cert_for_services" {
  zone_id = local.cloudflare_zone_id
  type    = "advanced"
  hosts = [
    local.root_domain,

    # 整地鯖が提供している経路
    "*.gigantic.${local.root_domain}",
    "*.map.gigantic.${local.root_domain}",

    # 整地鯖（春）が提供している経路
    "*.spring.${local.root_domain}",
    "*.map.spring.${local.root_domain}",
  ]
  validation_method     = "txt"
  validity_days         = 365
  certificate_authority = "digicert"
  cloudflare_branding   = false
}
