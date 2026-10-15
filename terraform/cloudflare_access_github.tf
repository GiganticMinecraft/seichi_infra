resource "cloudflare_zero_trust_access_identity_provider" "github_oauth" {
  zone_id = local.cloudflare_zone_id
  name    = "GitHub OAuth"
  type    = "github"
  config = {
    client_id     = var.github_cloudflare_oauth_client_id
    client_secret = var.github_cloudflare_oauth_client_secret
    # cloudflare provider 5.28.0 で追加された属性(デフォルト false)。
    # Access ログインページでのパスキー自動プロンプト。GitHub OAuth では使わないため明示的に無効化する。
    login_page_auto_prompt = false
  }

  lifecycle {
    ignore_changes = [config.client_secret]
  }
}
