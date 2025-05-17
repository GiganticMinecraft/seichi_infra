#region seichi-portal

resource "cloudflare_pages_project" "seichi_portal" {
  account_id        = local.cloudflare_account_id
  name              = "seichi-portal"
  production_branch = "main"
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
  deployment_configs {
    preview {
      # No config
    }
    production {
      # No config
    }
  }
  source {
    type = "github"
    config {
      owner             = local.github_org_name
      repo_name         = "seichi-playguide"
      production_branch = "main"
    }
  }
}

resource "cloudflare_pages_domain" "seichi_playguide_domain" {
  account_id   = local.cloudflare_account_id
  project_name = cloudflare_pages_project.seichi_playguide.name
  domain       = "playguide.${local.root_domain}"
}

#endregion
