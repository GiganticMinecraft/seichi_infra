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

# ローカルにトンネルを生やしてアクセスすることを想定したドメイン。
#
# 例えば、オンプレのk8sクラスタのAPIエンドポイントへは、
# ローカルポートをTCPプロキシにバインドしてアクセスすることを想定している。
# こういったケースでは、
#  - k8s-api.onp-k8s.admin.local-tunnels.seichi.click が 127.0.0.1 を向いている
#  - APIエンドポイントのTLS証明書のSANに k8s-api.onp-k8s.admin.local-tunnels.seichi.click が書かれている
# が満たされていれば良いため、
# この要求を満たすように cloudflare_record.local_tunnels のようなAレコードを入れている。
resource "cloudflare_record" "local_tunnels" {
  zone_id = local.cloudflare_zone_id
  name    = "*.local-tunnels.seichi.click"
  value   = "127.0.0.1"
  type    = "A"
  ttl     = 1 # automatic
}
