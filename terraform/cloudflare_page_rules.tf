resource "cloudflare_page_rule" "seichi_maps" {
  zone_id  = local.cloudflare_zone_id
  priority = 1
  target   = "*.map.gigantic.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}

resource "cloudflare_page_rule" "spring_maps" {
  depends_on = [cloudflare_page_rule.seichi_maps]

  zone_id  = local.cloudflare_zone_id
  priority = 2
  target   = "*.map.spring.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}

resource "cloudflare_page_rule" "seichi_ranking" {
  depends_on = [cloudflare_page_rule.spring_maps]

  zone_id  = local.cloudflare_zone_id
  priority = 3
  target   = "ranking-gigantic.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}
