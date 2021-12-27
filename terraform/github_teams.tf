resource "github_team" "nginx_test_connection_team" {
  name        = "nginx-test-connection-team"
  description = "テスト用のTeam。このTeamのメンバーのみ public-nginx.test.seichi.click にアクセスできるはず。"
  # 外部からは見えないっぽいのでこれでOK
  #  > Visible teams can be viewed and @mentioned by every organization member.
  #    https://docs.github.com/en/organizations/organizing-members-into-teams/changing-team-visibility
  # 具体的なメンバーは別リポジトリで管理すれば良い
  privacy     = "closed"
}

resource "github_team" "nginx_test_connection_team_nested" {
  name        = "nginx-test-connection-team-nested"
  description = "テスト用のTeam。"
  parent_team_id = github_team.nginx_test_connection_team.id
  privacy     = "closed"  
}
