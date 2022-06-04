resource "cloudflare_page_rule" "seichi_maps_old" {
  zone_id  = local.cloudflare_zone_id
  priority = 1
  target   = "*-map-gigantic.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}

resource "cloudflare_page_rule" "spring_maps_old" {
  zone_id  = local.cloudflare_zone_id
  priority = cloudflare_page_rule.seichi_maps_old.priority
  target   = "*-map-spring.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}

resource "cloudflare_page_rule" "seichi_ranking" {
  zone_id  = local.cloudflare_zone_id
  priority = cloudflare_page_rule.spring_maps_old.priority
  target   = "ranking-gigantic.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}

resource "cloudflare_page_rule" "seichi_maps" {
  zone_id  = local.cloudflare_zone_id
  priority = cloudflare_page_rule.seichi_ranking.priority
  target   = "*.map.gigantic.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}

resource "cloudflare_page_rule" "spring_maps" {
  zone_id  = local.cloudflare_zone_id
  priority = cloudflare_page_rule.seichi_maps.priority
  target   = "*.map.spring.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}
