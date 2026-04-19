#region seichi-playguide

resource "cloudflare_pages_project" "seichi_playguide" {
  account_id        = local.cloudflare_account_id
  name              = "seichi-playguide"
  production_branch = "main"

  build_config = {
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
      pr_comments_enabled            = true
      production_deployments_enabled = true
      preview_deployment_setting     = "all"
    }
  }
}

resource "cloudflare_pages_domain" "seichi_playguide_domain" {
  account_id   = local.cloudflare_account_id
  project_name = cloudflare_pages_project.seichi_playguide.name
  name         = "playguide.${local.root_domain}"
}

#endregion
