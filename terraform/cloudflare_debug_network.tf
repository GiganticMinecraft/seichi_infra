# VPSからオンプレに繋ぐための(Cloudflare tunnelを経由する)TCPネットワーク

resource "cloudflare_certificate_pack" "advanced_cert_for_tcp_debug_network" {
  zone_id               = local.cloudflare_zone_id
  type                  = "advanced"
  hosts                 = [local.root_domain, "tcp-debug-network.${local.root_domain}", "*.tcp-debug-network.${local.root_domain}"]
  validation_method     = "txt"
  validity_days         = 365
  certificate_authority = "digicert"
  cloudflare_branding   = false  
}

resource "cloudflare_access_application" "debug_vps_to_op_network" {
  zone_id                   = local.cloudflare_zone_id
  name                      = "Debug Network"
  domain                    = "*.tcp-debug-network.${local.root_domain}"
  type                      = "self_hosted"
  # オンプレ側が1日に1回再起動するのでセッション長は高々24時間になる
  session_duration          = "30h"
}

resource "cloudflare_access_service_token" "debug_linode_to_onp" {
  zone_id    = local.cloudflare_zone_id
  name       = "Linode (for Debug Network)"

  # サービストークンの有効期限は、最後に生成/renewされてから365日となっている。
  # そこで、トークンの有効期限が切れる30日前以降は terraform apply されたときにrenewするように設定しておく。
  # FIXME: これrefreshじゃなさそう　生成後335日以降は普通にtokenがregenerateされて困る
  min_days_for_renewal = 365

  lifecycle {
    # This flag is important to set if min_days_for_renewal is defined otherwise 
    # there will be a brief period where the service relying on that token 
    # will not have access due to the resource being deleted
    create_before_destroy = true
  }
}

resource "cloudflare_access_policy" "debug_linode_to_onp" {
  application_id = cloudflare_access_application.debug_vps_to_op_network.id
  zone_id        = local.cloudflare_zone_id
  name           = "Require service token for access"
  precedence     = "1"
  # allow/deny での制御にすると、クライアントとなるcloudflaredが起動するときにブラウザ経由の認証を求められる。
  # Service account token による制御ではそんなことは無いが、 decision を non_identity とする必要がある。
  # 詳細は https://developers.cloudflare.com/cloudflare-one/policies/zero-trust#actions を参照のこと
  decision       = "non_identity"

  include {
    service_token = [
      cloudflare_access_service_token.debug_linode_to_onp.id
    ]
  }
}
