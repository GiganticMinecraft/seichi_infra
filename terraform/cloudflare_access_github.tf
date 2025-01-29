resource "cloudflare_zero_trust_access_identity_provider" "github_oauth" {
  account_id = local.cloudflare_account_id
  name    = "GitHub OAuth"
  type    = "github"
  config {
    client_id     = var.github_cloudflare_oauth_client_id
    client_secret = var.github_cloudflare_oauth_client_secret
  }
}
