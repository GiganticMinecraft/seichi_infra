# 整地鯖管理者が、デバッグ目的や監査目的で各種サービスに接続する必要がある際に経由するネットワーク。
resource "cloudflare_certificate_pack" "advanced_cert_for_admin_network" {
  zone_id = local.cloudflare_zone_id
  type    = "advanced"
  hosts = [
    local.root_domain,
    "*.onp-k8s.admin.${local.root_domain}",
    "*.onp.admin.${local.root_domain}",
    "*.debug.admin.${local.root_domain}",
  ]
  validation_method     = "txt"
  validity_days         = 365
  certificate_authority = "digicert"
  cloudflare_branding   = false
}

resource "cloudflare_access_application" "debug_admin_jmx" {
  zone_id          = local.cloudflare_zone_id
  name             = "Debug server administration"
  domain           = "jmx.debug.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true
}

resource "cloudflare_access_policy" "debug_admin_jmx" {
  application_id = cloudflare_access_application.debug_admin_jmx.id
  zone_id        = local.cloudflare_zone_id
  name           = "Require to be in a GitHub team to access"
  precedence     = "1"
  decision       = "allow"

  include {
    github {
      name                 = local.github_org_name
      teams                = [github_team.debug_admin_jmx.slug]
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
    }
  }
}

resource "cloudflare_access_application" "onp_admin_proxmox" {
  zone_id          = local.cloudflare_zone_id
  name             = "Proxmox administration"
  domain           = "proxmox.onp.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true
}

resource "cloudflare_access_policy" "onp_admin_proxmox" {
  application_id = cloudflare_access_application.onp_admin_proxmox.id
  zone_id        = local.cloudflare_zone_id
  name           = "Require to be in a GitHub team to access"
  precedence     = "1"
  decision       = "allow"

  include {
    github {
      name                 = local.github_org_name
      teams                = [github_team.onp_admin_proxmox.slug]
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
    }
  }
}

resource "cloudflare_access_application" "onp_admin_minio" {
  zone_id          = local.cloudflare_zone_id
  name             = "minio-console administration"
  domain           = "minio-console.onp-k8s.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true
}

resource "cloudflare_access_policy" "onp_admin_minio" {
  application_id = cloudflare_access_application.onp_admin_minio.id
  zone_id        = local.cloudflare_zone_id
  name           = "Require to be in a GitHub team to access"
  precedence     = "1"
  decision       = "allow"

  include {
    github {
      name                 = local.github_org_name
      teams                = [github_team.onp_admin_minio.slug]
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
    }
  }
}
