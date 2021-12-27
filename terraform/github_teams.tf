resource "github_team" "nginx_test_connection_team" {
  name        = "nginx-test-connection-team"
  description = "テスト用のTeam。このTeamのメンバーのみ public-nginx.test.seichi.click にアクセスできるはず。"
  privacy     = "secret"
}

resource "github_team" "nginx_test_connection_team_nested" {
  name        = "nginx-test-connection-team-nested"
  description = "テスト用のTeam。"
  parent_team_id = github_team.nginx_test_connection_team.id
  privacy     = "secret"  
}
