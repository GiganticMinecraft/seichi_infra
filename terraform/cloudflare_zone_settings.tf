resource "cloudflare_zone_setting" "email_obfuscation" {
  zone_id    = local.cloudflare_zone_id
  setting_id = "email_obfuscation"
  value      = "off"
}
