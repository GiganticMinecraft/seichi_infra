# 整地鯖管理者が、デバッグ目的などで内部的なサービスに接続する必要がある際に経由するネットワーク。
# NOTE: Certificate Pack は Cloudflare 側で自動管理されているため、Terraform 管理外としています。

resource "cloudflare_access_application" "game_data_server" {
  zone_id          = local.cloudflare_zone_id
  name             = "Access to game data server"
  domain           = "game-data-server.readonly-internal.onp-k8s.admin.${local.root_domain}"
  type             = "self_hosted"
  session_duration = "24h"

  http_only_cookie_attribute = true
}

resource "cloudflare_access_policy" "game_data_server" {
  application_id = cloudflare_access_application.game_data_server.id
  zone_id        = local.cloudflare_zone_id
  name           = "Require to be in a GitHub team to access"
  precedence     = "1"
  decision       = "allow"

  include {
    github {
      name                 = local.github_org_name
      teams                = [github_team.prod_seichi_minecraft_readonly_services_access.slug]
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
    }
  }
}
