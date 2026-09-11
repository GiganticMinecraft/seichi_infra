resource "cloudflare_ruleset" "configuration_rules" {
  zone_id     = local.cloudflare_zone_id
  name        = "default"
  description = "Cloudflare configuration rules"
  kind        = "zone"
  phase       = "http_config_settings"

  rules = [
    {
      ref         = "disable_email_obfuscation_for_seichi_portal"
      action      = "set_config"
      expression  = "(http.host eq \"portal.${local.root_domain}\")"
      description = "seichi-portal の React hydration 前にメールアドレスが書き換わるのを防ぐ"
      action_parameters = {
        email_obfuscation = false
      }
      enabled = true
    },
  ]
}
