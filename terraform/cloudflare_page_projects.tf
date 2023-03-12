#region seichi-portal

resource "cloudflare_pages_project" "seichi_portal" {
  account_id        = local.cloudflare_account_id
  name              = "seichi-portal"
  production_branch = "main"
  build_config {
    build_command   = "yarn build"
    destination_dir = "out"
    root_dir        = "/"
  }
  deployment_configs {
    production {
      environment_variables = {
        NODE_ENV                        = "production"
        NEXT_PUBLIC_BACKEND_API_URL     = var.cloudflare_pages__seichi_portal__next_public_backend_api_url
        NEXT_PUBLIC_MS_APP_CLIENT_ID    = var.cloudflare_pages__seichi_portal__next_public_ms_app_client_id
        NEXT_PUBLIC_MS_APP_REDIRECT_URL = "https://${cloudflare_pages_domain.seichi_portal_domain.domain}"
      }
    }
  }
  source {
    type = "github"
    config {
      owner             = local.github_org_name
      repo_name         = "seichi-portal-frontend"
      production_branch = "main"
    }
  }
}

resource "cloudflare_pages_domain" "seichi_portal_domain" {
  account_id   = local.cloudflare_account_id
  project_name = cloudflare_pages_project.seichi_portal.name
  domain       = "portal.${local.root_domain}"
}

#endregion
