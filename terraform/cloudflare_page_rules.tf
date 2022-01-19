resource "cloudflare_page_rule" "resource_packs" {
  zone_id = local.cloudflare_zone_id
  # TODO ちゃんとしたドメインへ移行
  target = "s1-map-gigantic.${local.root_domain}/resourcepacks/*"

  actions {
    browser_check = "off"
  }
}

resource "cloudflare_page_rule" "seichi_maps" {
  zone_id = local.cloudflare_zone_id
  target = "*-map-gigantic.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}

resource "cloudflare_page_rule" "spring_maps" {
  zone_id = local.cloudflare_zone_id
  target = "*-map-spring.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}

resource "cloudflare_page_rule" "seichi_ranking" {
  zone_id = local.cloudflare_zone_id
  target = "ranking-gigantic.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}


