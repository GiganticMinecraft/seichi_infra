# Cloudflare provider v4 → v5 移行用の import ブロック。
# ステートから除去された既存リソースを v5 の新リソースタイプとして再インポートする。
# apply 完了後、このファイルは削除可能。

# region DNS Records

import {
  to = cloudflare_dns_record.play
  id = "77c10fdfa7c65de4d14903ed8879ebcb/e07a5219d88908d9685e79c4fb5897cd"
}

import {
  to = cloudflare_dns_record.play_debug
  id = "77c10fdfa7c65de4d14903ed8879ebcb/9bb459d7396a0a541f0b95862c7bf111"
}

import {
  to = cloudflare_dns_record.github_pages
  id = "77c10fdfa7c65de4d14903ed8879ebcb/40e2325230ddaec404e54304a2686c95"
}

import {
  to = cloudflare_dns_record.github_pages_command_reference
  id = "77c10fdfa7c65de4d14903ed8879ebcb/7f1b41076b7a9e6f556e380219d2de65"
}

import {
  to = cloudflare_dns_record.portal
  id = "77c10fdfa7c65de4d14903ed8879ebcb/81784b1c8b1e599f0a1730092df1e819"
}

import {
  to = cloudflare_dns_record.playguide
  id = "77c10fdfa7c65de4d14903ed8879ebcb/fc7936c45cf60dbdf751f004389e78d1"
}

import {
  to = cloudflare_dns_record.local_tunnels
  id = "77c10fdfa7c65de4d14903ed8879ebcb/77a422a72227c1fab2a8bf69389733f2"
}

# endregion

# region Access Applications

import {
  to = cloudflare_zero_trust_access_application.debug_admin_jmx
  id = "zones/77c10fdfa7c65de4d14903ed8879ebcb/df72db20-c95f-4b37-9546-bdd59d28715f"
}

import {
  to = cloudflare_zero_trust_access_application.onp_admin_proxmox
  id = "zones/77c10fdfa7c65de4d14903ed8879ebcb/c2dd0a2a-733f-4845-97a0-7ed87553af8e"
}

import {
  to = cloudflare_zero_trust_access_application.onp_admin_proxmox_mon
  id = "zones/77c10fdfa7c65de4d14903ed8879ebcb/5087abac-83c1-4aa6-9f01-e902c72a6faf"
}

import {
  to = cloudflare_zero_trust_access_application.onp_admin_zabbix
  id = "zones/77c10fdfa7c65de4d14903ed8879ebcb/9ad7ec52-6019-4db0-adab-15db5242d415"
}

import {
  to = cloudflare_zero_trust_access_application.onp_admin_raritan
  id = "zones/77c10fdfa7c65de4d14903ed8879ebcb/4880490f-a146-40e7-86a9-9691b47726e4"
}

import {
  to = cloudflare_zero_trust_access_application.onp_hubble_ui
  id = "zones/77c10fdfa7c65de4d14903ed8879ebcb/998a0b26-1af2-4a3d-a746-651da92f42f7"
}

import {
  to = cloudflare_zero_trust_access_application.onp_phpmyadmin
  id = "zones/77c10fdfa7c65de4d14903ed8879ebcb/dd1bc2c5-2828-43d3-87df-465875a0b022"
}

import {
  to = cloudflare_zero_trust_access_application.onp_bugsink
  id = "zones/77c10fdfa7c65de4d14903ed8879ebcb/81ef7b64-1bfc-4489-a52e-91b28c96bb1f"
}

import {
  to = cloudflare_zero_trust_access_application.onp_goldilocks
  id = "zones/77c10fdfa7c65de4d14903ed8879ebcb/79b3c4cc-6031-409f-9fd8-34129a61b2e3"
}

import {
  to = cloudflare_zero_trust_access_application.game_data_server
  id = "zones/77c10fdfa7c65de4d14903ed8879ebcb/c14b6f82-8862-4c5c-a7c0-e65937e90507"
}

# endregion

# region Page Rules

import {
  to = cloudflare_page_rule.global
  id = "77c10fdfa7c65de4d14903ed8879ebcb/d279b263ac9994eafd9c763adee5a53b"
}

import {
  to = cloudflare_page_rule.seichi_maps
  id = "77c10fdfa7c65de4d14903ed8879ebcb/3622ba2c1baee28921f3c6af67847982"
}

import {
  to = cloudflare_page_rule.spring_maps
  id = "77c10fdfa7c65de4d14903ed8879ebcb/aa61a1ff297766c7b1f39180fa58c86b"
}

import {
  to = cloudflare_page_rule.cache_public_game_data_api
  id = "77c10fdfa7c65de4d14903ed8879ebcb/6be6095953e09f3178bb8d5bfda5bf51"
}

import {
  to = cloudflare_page_rule.disable_security_on_sentry_api
  id = "77c10fdfa7c65de4d14903ed8879ebcb/8d945497e9d21976ffae5bd475f8a8a6"
}

# endregion

# region Rulesets (transform rules - firewall rules は既にステートにある)

import {
  to = cloudflare_ruleset.seichi_portal_transform_for_cors
  id = "zones/77c10fdfa7c65de4d14903ed8879ebcb/e22e283066b842fd98243e72c685051a"
}

# endregion

# region Pages Projects

import {
  to = cloudflare_pages_project.seichi_portal
  id = "9e9e88e2b19878c4a911c3c8a715a168/seichi-portal"
}

import {
  to = cloudflare_pages_project.seichi_playguide
  id = "9e9e88e2b19878c4a911c3c8a715a168/seichi-playguide"
}

# endregion

# region Pages Domains

import {
  to = cloudflare_pages_domain.seichi_portal_domain
  id = "9e9e88e2b19878c4a911c3c8a715a168/seichi-portal/portal.seichi.click"
}

import {
  to = cloudflare_pages_domain.seichi_playguide_domain
  id = "9e9e88e2b19878c4a911c3c8a715a168/seichi-playguide/playguide.seichi.click"
}

# endregion

# region Access Identity Provider (既にステートにあるが念のため)
# cloudflare_zero_trust_access_identity_provider.github_oauth は既にインポート済み
# endregion
