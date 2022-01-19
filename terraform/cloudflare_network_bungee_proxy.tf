# BungeeCord等のプロキシが走るk8sクラスタが露出する全体公開用のネットワーク

resource "cloudflare_certificate_pack" "advanced_cert_for_bungee_proxy_network" {
  zone_id               = local.cloudflare_zone_id
  type                  = "advanced"
  hosts                 = [
    local.root_domain,
    "*.bungee-proxy.${local.root_domain}",
  ]
  validation_method     = "txt"
  validity_days         = 365
  certificate_authority = "digicert"
  cloudflare_branding   = false  
}

