# 当レポジトリではチームの存在のみ管理し、
# 具体的なメンバーは別リポジトリ (GiganticMinecraft/teams) で管理することとする

# 可視性に関しては、 privacy = "closed" で外部からは見えないのでOK
#  > Visible teams can be viewed and @mentioned by every organization member.
#  (https://docs.github.com/en/organizations/organizing-members-into-teams/changing-team-visibility)

resource "github_team" "admin_team" {
  name        = "admin-team"
  description = "運営チーム"
  privacy     = "closed"
}

resource "github_team" "infra_collaborator" {
  name        = "infra-collaborator"
  description = "インフラ関連の外部コラボレーター"
  privacy     = "closed"
}

resource "github_team" "debug_admin_jmx" {
  name        = "debug-admin-jmx"
  description = "デバッグサーバーのJMXに接続できるTeam"
  privacy     = "closed"
}

resource "github_team" "onp_admin_grafana_team" {
  name        = "onp-admin-grafana"
  description = "オンプレミス環境のgrafanaに接続できるTeam"
  privacy     = "closed"
}

resource "github_team" "onp_admin_proxmox_team" {
  name        = "onp-admin-proxmox"
  description = "オンプレミス環境のproxmoxに接続できるTeam"
  privacy     = "closed"
}

resource "github_team" "springer" {
  name        = "Springer"
  description = "整地鯖(春)のデベロッパー"
  privacy     = "closed"
}
