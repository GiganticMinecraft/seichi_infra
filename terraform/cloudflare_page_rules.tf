resource "cloudflare_page_rule" "global" {
  zone_id  = local.cloudflare_zone_id
  priority = 1
  # 全サブドメイン配下の全パスについて適用する
  # https://developers.cloudflare.com/support/page-rules/understanding-and-configuring-cloudflare-page-rules-page-rules-tutorial/#helpful-tips
  target = "*_${local.root_domain}/*"

  actions {
    # https://github.com/GiganticMinecraft/seichi_infra/issues/1094#issuecomment-1599150661
    minify {
      html = "on"
      css  = "on"
      js   = "off"
    }
  }
}

resource "cloudflare_page_rule" "seichi_maps" {
  zone_id  = local.cloudflare_zone_id
  priority = cloudflare_page_rule.global.priority + 1
  target   = "*.map.gigantic.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}

resource "cloudflare_page_rule" "spring_maps" {
  zone_id  = local.cloudflare_zone_id
  priority = cloudflare_page_rule.seichi_maps.priority + 1
  target   = "*.map.spring.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}

resource "cloudflare_page_rule" "cache_public_game_data_api" {
  zone_id  = local.cloudflare_zone_id
  priority = cloudflare_page_rule.spring_maps.priority + 1
  target   = "seichi-game-data.public-gigantic-api.${local.root_domain}/*"

  actions {
    cache_level = "cache_everything"
  }
}

resource "cloudflare_page_rule" "disable_security_on_sentry_api" {
  zone_id  = local.cloudflare_zone_id
  priority = cloudflare_page_rule.cache_public_game_data_api.priority + 1
  target   = "sentry.onp.admin.${local.root_domain}/api/*"

  actions {
    # Security を disable しない場合、Sentry の performance monitoring 用の API コールが
    # Cloudflare の challenge に引っかかってしまうため disable している
    disable_security = true
  }
}
