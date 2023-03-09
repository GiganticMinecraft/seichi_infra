resource "cloudflare_ruleset" "seichi_portal_transform_for_cors" {
  zone_id     = local.cloudflare_zone_id
  name        = "transform rule for HTTP headers"
  description = "SeichiPortalが外部APIにアクセスするのに必要な、レスポンスヘッダーの設定を編集する"
  kind        = "zone"
  phase       = "http_response_headers_transform"

  rules {
    action = "rewrite"
    action_parameters {
      headers {
        name      = "Access-Control-Allow-Origin"
        operation = "set"
        value     = "https://portal.seichi.click"
      }
    }

    expression  = "http.host contains \"portal.seichi.click\""
    description = "SeichiPortalが外部APIにアクセスするのに必要な、レスポンスヘッダーの設定を編集する"
    enabled     = true
  }
}
