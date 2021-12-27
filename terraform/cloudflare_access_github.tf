resource "cloudflare_access_identity_provider" "github_oauth" {
  zone_id    = local.cloudflare_zone_id
  name       = "GitHub OAuth"
  type       = "github"
  config {
    client_id     = var.github_cloudflare_oauth_client_id
    client_secret = var.github_cloudflare_oauth_client_secret
  }
}
