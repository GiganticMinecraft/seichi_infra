data "github_repository" "seichi_infra" {
  full_name = "GiganticMinecraft/seichi_infra"
}

resource "github_branch_protection" "example" {
  repository_id = data.github_repository.seichi_infra.node_id

  pattern          = "main"
  enforce_admins   = true
  allows_deletions = false

  required_status_checks {
    strict   = true
    contexts = [
        "Terraform Cloud/GiganticMinecraft/seichi_infra",
        "shellcheck with reviewdog",
        "runner / tflint"
    ]
  }

  required_pull_request_reviews {
    dismiss_stale_reviews  = true
    required_approving_review_count = 1
  }
}
