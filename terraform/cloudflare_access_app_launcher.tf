# Cloudflare Access の App Launcher (https://seichiclick.cloudflareaccess.com/)。
# 2022 年にダッシュボードから作成されたものを Terraform 管理下に取り込んでいる。
# 元のポリシーは削除済みの IdP を参照していてログインできない状態だったため、
# 他の Access アプリと同じく Terraform 管理の GitHub OAuth IdP を使うようにしている。

resource "cloudflare_zero_trust_access_application" "app_launcher" {
  account_id       = local.cloudflare_account_id
  name             = "App Launcher"
  type             = "app_launcher"
  session_duration = "24h"

  allowed_idps = [cloudflare_zero_trust_access_identity_provider.github_oauth.id]

  # API は App Launcher の landing_page_design を常に {} で返すため、未指定 (null) のままだと
  # 毎回 `{} -> null` の差分が出る。空オブジェクトを明示して API の値と一致させる。
  landing_page_design = {}

  policies = [{
    decision   = "allow"
    name       = "Require to be in the GitHub organization to access"
    precedence = 1
    include = [{
      github_organization = {
        name                 = local.github_org_name
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.github_oauth.id
      }
    }]
  }]
}
