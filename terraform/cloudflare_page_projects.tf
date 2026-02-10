#region seichi-portal

resource "cloudflare_pages_project" "seichi_portal" {
  account_id        = local.cloudflare_account_id
  name              = "seichi-portal"
  production_branch = "main"

  deployment_configs = {
    preview = {
      compatibility_date = "2023-03-19"
    }
    production = {
      compatibility_date = "2023-03-19"
      env_vars = {
        NEXT_PUBLIC_BACKEND_API_URL = {
          type  = "plain_text"
          value = var.cloudflare_pages__seichi_portal__next_public_backend_api_url
        }
        NEXT_PUBLIC_MS_APP_CLIENT_ID = {
          type  = "plain_text"
          value = var.cloudflare_pages__seichi_portal__next_public_ms_app_client_id
        }
        NEXT_PUBLIC_MS_APP_REDIRECT_URL = {
          type  = "plain_text"
          value = "https://portal.${local.root_domain}"
        }
        NODE_ENV = {
          type  = "plain_text"
          value = "production"
        }
      }
    }
  }

  source = {
    type = "github"
    config = {
      owner                          = local.github_org_name
      repo_name                      = "seichi-portal-frontend"
      production_branch              = "main"
      preview_branch_includes        = ["*"]
      deployments_enabled            = true
      pr_comments_enabled            = true
      production_deployments_enabled = true
    }
  }
}

resource "cloudflare_pages_domain" "seichi_portal_domain" {
  account_id   = local.cloudflare_account_id
  project_name = cloudflare_pages_project.seichi_portal.name
  domain       = "portal.${local.root_domain}"
}

#endregion

#region seichi-playguide

resource "cloudflare_pages_project" "seichi_playguide" {
  account_id        = local.cloudflare_account_id
  name              = "seichi-playguide"
  production_branch = "main"

  build_config {
    build_command   = "npx vitepress build"
    destination_dir = ".vitepress/dist"
    root_dir        = "/"
  }

  deployment_configs = {
    preview = {
      compatibility_date = "2025-05-24"
    }
    production = {
      compatibility_date = "2025-05-24"
    }
  }

  source = {
    type = "github"
    config = {
      owner                          = local.github_org_name
      repo_name                      = "seichi-playguide"
      production_branch              = "main"
      preview_branch_includes        = ["*"]
      deployments_enabled            = true
      pr_comments_enabled            = true
      production_deployments_enabled = true
    }
  }
}

resource "cloudflare_pages_domain" "seichi_playguide_domain" {
  account_id   = local.cloudflare_account_id
  project_name = cloudflare_pages_project.seichi_playguide.name
  domain       = "playguide.${local.root_domain}"
}

#endregion
