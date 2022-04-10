# 向き先を指定する必要があるDNSレコードのリソース

resource "cloudflare_record" "play" {
  zone_id = local.cloudflare_zone_id
  name    = "play"
  value   = "nrt.premium-aws.tcpshield.com"
  type    = "CNAME"
  ttl     = 1 # automatic
}

resource "cloudflare_record" "play_debug" {
  zone_id = local.cloudflare_zone_id
  name    = "play-debug"
  value   = "nrt.premium-aws.tcpshield.com"
  type    = "CNAME"
  ttl     = 1 # automatic
}
