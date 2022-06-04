# エンドユーザーが直接アクセスするドメインを保護する certificate pack。
resource "cloudflare_certificate_pack" "advanced_cert_for_services" {
  zone_id = local.cloudflare_zone_id
  type    = "advanced"
  hosts = [
    local.root_domain,

    "*.gigantic.${local.root_domain}",
    "*.map.gigantic.${local.root_domain}",

    "*.spring.${local.root_domain}",
    "*.map.spring.${local.root_domain}",
  ]
  validation_method     = "txt"
  validity_days         = 365
  certificate_authority = "digicert"
  cloudflare_branding   = false
}
