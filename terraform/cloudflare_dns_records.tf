# 向き先を指定する必要があるDNSレコードのリソース

moved {
  from = cloudflare_record.play
  to   = cloudflare_dns_record.play
}
resource "cloudflare_dns_record" "play" {
  zone_id = local.cloudflare_zone_id
  name    = "play.seichi.click"
  content = "nrt.premium-aws.tcpshield.com"
  type    = "CNAME"
  ttl     = 1 # automatic
}

moved {
  from = cloudflare_record.play_debug
  to   = cloudflare_dns_record.play_debug
}
resource "cloudflare_dns_record" "play_debug" {
  zone_id = local.cloudflare_zone_id
  name    = "play-debug.seichi.click"
  content = "nrt.premium-aws.tcpshield.com"
  type    = "CNAME"
  ttl     = 1 # automatic
}

moved {
  from = cloudflare_record.github_pages
  to   = cloudflare_dns_record.github_pages
}
resource "cloudflare_dns_record" "github_pages" {
  zone_id = local.cloudflare_zone_id
  name    = "_github-pages-challenge-GiganticMinecraft.seichi.click"
  content = "e6145d3fd4824da7133309fa2dd2c6"
  type    = "TXT"
  ttl     = 1 # automatic
}

moved {
  from = cloudflare_record.github_pages_command_reference
  to   = cloudflare_dns_record.github_pages_command_reference
}
resource "cloudflare_dns_record" "github_pages_command_reference" {
  zone_id = local.cloudflare_zone_id
  name    = "cmd.seichi.click"
  content = "giganticminecraft.github.io"
  type    = "CNAME"
  ttl     = 1 # automatic
}

moved {
  from = cloudflare_record.portal
  to   = cloudflare_dns_record.portal
}
resource "cloudflare_dns_record" "portal" {
  zone_id = local.cloudflare_zone_id
  name    = "portal.seichi.click"
  content = "${cloudflare_pages_project.seichi_portal.name}.pages.dev"
  type    = "CNAME"
  ttl     = 1 # automatic
}

moved {
  from = cloudflare_record.playguide
  to   = cloudflare_dns_record.playguide
}
resource "cloudflare_dns_record" "playguide" {
  zone_id = local.cloudflare_zone_id
  name    = "playguide.seichi.click"
  content = "${cloudflare_pages_project.seichi_playguide.name}.pages.dev"
  type    = "CNAME"
  ttl     = 1 # automatic
}

# ローカルにトンネルを生やしてアクセスすることを想定したドメイン。
#
# 例えば、オンプレのk8sクラスタのAPIエンドポイントへは、
# ローカルポートをTCPプロキシにバインドしてアクセスすることを想定している。
# こういったケースでは、
#  - k8s-api.onp-k8s.admin.local-tunnels.seichi.click が 127.0.0.1 を向いている
#  - APIエンドポイントのTLS証明書のSANに k8s-api.onp-k8s.admin.local-tunnels.seichi.click が書かれている
# が満たされていれば良いため、
# この要求を満たすように cloudflare_dns_record.local_tunnels のようなAレコードを入れている。
moved {
  from = cloudflare_record.local_tunnels
  to   = cloudflare_dns_record.local_tunnels
}
resource "cloudflare_dns_record" "local_tunnels" {
  zone_id = local.cloudflare_zone_id
  name    = "*.local-tunnels.seichi.click"
  content = "127.0.0.1"
  type    = "A"
  ttl     = 1 # automatic
}
