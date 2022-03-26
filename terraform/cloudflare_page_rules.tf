resource "cloudflare_page_rule" "seichi_maps" {
  zone_id = local.cloudflare_zone_id
  priority = 1
  target = "*-map-gigantic.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}

resource "cloudflare_page_rule" "resource_packs" {
  # Cloudflare の page rule の priority は first-come-first-served で割り当てられるため、
  # priority の順に依存関係を追加しなければならない
  # see: https://github.com/cloudflare/terraform-provider-cloudflare/issues/187#issuecomment-450987683
  depends_on = [cloudflare_page_rule.seichi_maps]

  zone_id = local.cloudflare_zone_id
  # seichi_mapsルールから除外したいため、priorityを指定しておく
  priority = 2
  # TODO ちゃんとしたドメインへ移行
  target = "s1-map-gigantic.${local.root_domain}/resourcepacks/*"

  actions {
    security_level = "high"
    browser_check = "off"
  }
}

resource "cloudflare_page_rule" "spring_maps" {
  depends_on = [cloudflare_page_rule.resource_packs]

  zone_id = local.cloudflare_zone_id
  priority = 3
  target = "*-map-spring.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}

resource "cloudflare_page_rule" "seichi_ranking" {
  depends_on = [cloudflare_page_rule.spring_maps]

  zone_id = local.cloudflare_zone_id
  priority = 4
  target = "ranking-gigantic.${local.root_domain}/*"

  actions {
    security_level = "under_attack"
  }
}


