data "cloudflare_api_token_permission_groups" "all" {}

resource "cloudflare_api_token" "pages_api_token" {
  name = "pages-api-token"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.permissions["Access: Audit Logs Read"],
    ]
    resources = {
      "com.cloudflare.api.account.*" = "*"
    }
  }
}
