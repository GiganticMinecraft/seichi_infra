# Cloudflare Dashboardに既存Widgetがある場合は、新規作成前に以下でStateへ取り込む。
# terraform -chdir=terraform import cloudflare_turnstile_widget.seichi_portal <account_id>/<sitekey>
# import後は plan で差分・置換の有無を確認してから apply する。
resource "cloudflare_turnstile_widget" "seichi_portal" {
  account_id = local.cloudflare_account_id
  name       = "seichi-portal"
  domains    = ["portal.seichi.click"]
  mode       = "managed"
  region     = "world"
}
