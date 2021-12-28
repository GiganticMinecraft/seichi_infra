# 外部からは見えないっぽいので privacy = "closed" でOK
#  > Visible teams can be viewed and @mentioned by every organization member.
#    https://docs.github.com/en/organizations/organizing-members-into-teams/changing-team-visibility
# 具体的なメンバーは別リポジトリ (GiganticMinecraft/teams) で管理することとする

resource "github_team" "admin_team" {
  name        = "Admin team"
  description = "運営チーム"
  privacy     = "closed"
}

resource "github_team" "infra_collaborator" {
  name        = "Infra Collaborator"
  description = "インフラ関連の外部コラボレーター"
  privacy     = "closed"
}

resource "github_team" "nginx_test_connection_team" {
  name        = "nginx-test-connection-team"
  description = "テスト用のTeam。このTeamのメンバーのみ public-nginx.test.seichi.click にアクセスできるはず。"
  privacy     = "closed"
}

resource "github_team" "springer" {
  name        = "Springer"
  description = "整地鯖(春)のデベロッパー"
  privacy     = "closed"
}
