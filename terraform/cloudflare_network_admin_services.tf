# 整地鯖管理者が、デバッグ目的や監査目的で各種サービスに接続する必要がある際に経由するネットワーク。
# NOTE: Certificate Pack は Cloudflare 側で自動管理されているため、Terraform 管理外としています。

moved {
  from = cloudflare_access_application.debug_admin_jmx
  to   = cloudflare_zero_trust_access_application.debug_admin_jmx
}
resource "cloudflare_zero_trust_access_application" "debug_admin_jmx" {
  zone_id          = local.cloudflare_zone_id
  name             = "Debug server administration"
  domain           = "jmx.debug.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true

  policies = [{
    decision   = "allow"
    name       = "Require to be in a GitHub team to access"
    precedence = 1
    include = [{
      github_organization = {
        name                 = local.github_org_name
        team                 = github_team.debug_admin_jmx.slug
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.github_oauth.id
      }
    }]
  }]
}

moved {
  from = cloudflare_access_application.onp_admin_proxmox
  to   = cloudflare_zero_trust_access_application.onp_admin_proxmox
}
resource "cloudflare_zero_trust_access_application" "onp_admin_proxmox" {
  zone_id          = local.cloudflare_zone_id
  name             = "Proxmox administration"
  domain           = "proxmox.onp.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true

  policies = [{
    decision   = "allow"
    name       = "Require to be in a GitHub team to access"
    precedence = 1
    include = [{
      github_organization = {
        name                 = local.github_org_name
        team                 = github_team.onp_admin_proxmox.slug
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.github_oauth.id
      }
    }]
  }]
}

moved {
  from = cloudflare_access_application.onp_admin_proxmox_mon
  to   = cloudflare_zero_trust_access_application.onp_admin_proxmox_mon
}
resource "cloudflare_zero_trust_access_application" "onp_admin_proxmox_mon" {
  zone_id          = local.cloudflare_zone_id
  name             = "Proxmox-mon administration"
  domain           = "proxmox-mon.onp.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true

  policies = [{
    decision   = "allow"
    name       = "Require to be in a GitHub team to access"
    precedence = 1
    include = [{
      github_organization = {
        name                 = local.github_org_name
        team                 = github_team.onp_admin_proxmox_mon.slug
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.github_oauth.id
      }
    }]
  }]
}

moved {
  from = cloudflare_access_application.onp_admin_zabbix
  to   = cloudflare_zero_trust_access_application.onp_admin_zabbix
}
resource "cloudflare_zero_trust_access_application" "onp_admin_zabbix" {
  zone_id          = local.cloudflare_zone_id
  name             = "Zabbix administration"
  domain           = "zabbix.onp.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true

  policies = [{
    decision   = "allow"
    name       = "Require to be in a GitHub team to access"
    precedence = 1
    include = [{
      github_organization = {
        name                 = local.github_org_name
        team                 = github_team.onp_admin_zabbix.slug
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.github_oauth.id
      }
    }]
  }]
}

moved {
  from = cloudflare_access_application.onp_admin_raritan
  to   = cloudflare_zero_trust_access_application.onp_admin_raritan
}
resource "cloudflare_zero_trust_access_application" "onp_admin_raritan" {
  zone_id          = local.cloudflare_zone_id
  name             = "raritan(PDU) administration"
  domain           = "raritan.onp.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true

  policies = [{
    decision   = "allow"
    name       = "Require to be in a GitHub team to access"
    precedence = 1
    include = [{
      github_organization = {
        name                 = local.github_org_name
        team                 = github_team.onp_admin_raritan.slug
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.github_oauth.id
      }
    }]
  }]
}

moved {
  from = cloudflare_access_application.onp_admin_minio
  to   = cloudflare_zero_trust_access_application.onp_admin_minio
}
resource "cloudflare_zero_trust_access_application" "onp_admin_minio" {
  zone_id          = local.cloudflare_zone_id
  name             = "minio-console administration"
  domain           = "minio-console.onp-k8s.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true

  policies = [{
    decision   = "allow"
    name       = "Require to be in a GitHub team to access"
    precedence = 1
    include = [{
      github_organization = {
        name                 = local.github_org_name
        team                 = github_team.onp_admin_minio.slug
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.github_oauth.id
      }
    }]
  }]
}

moved {
  from = cloudflare_access_application.onp_hubble_ui
  to   = cloudflare_zero_trust_access_application.onp_hubble_ui
}
resource "cloudflare_zero_trust_access_application" "onp_hubble_ui" {
  zone_id          = local.cloudflare_zone_id
  name             = "Cilium Hubble UI"
  domain           = "hubble-ui.onp-k8s.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true

  policies = [{
    decision   = "allow"
    name       = "Require to be in a GitHub team to access"
    precedence = 1
    include = [{
      github_organization = {
        name                 = local.github_org_name
        team                 = github_team.onp_hubble_ui.slug
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.github_oauth.id
      }
    }]
  }]
}

moved {
  from = cloudflare_access_application.onp_phpmyadmin
  to   = cloudflare_zero_trust_access_application.onp_phpmyadmin
}
resource "cloudflare_zero_trust_access_application" "onp_phpmyadmin" {
  zone_id          = local.cloudflare_zone_id
  name             = "phpMyAdmin"
  domain           = "phpmyadmin.onp-k8s.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true

  policies = [{
    decision   = "allow"
    name       = "Require to be in a GitHub team to access"
    precedence = 1
    include = [{
      github_organization = {
        name                 = local.github_org_name
        team                 = github_team.onp_phpmyadmin.slug
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.github_oauth.id
      }
    }]
  }]
}

moved {
  from = cloudflare_access_application.onp_bugsink
  to   = cloudflare_zero_trust_access_application.onp_bugsink
}
resource "cloudflare_zero_trust_access_application" "onp_bugsink" {
  zone_id          = local.cloudflare_zone_id
  name             = "Bugsink"
  domain           = "bugsink.onp-k8s.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true

  policies = [{
    decision   = "allow"
    name       = "Require to be in a GitHub team to access"
    precedence = 1
    include = [{
      github_organization = {
        name                 = local.github_org_name
        team                 = github_team.onp_admin_bugsink.slug
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.github_oauth.id
      }
    }]
  }]
}
