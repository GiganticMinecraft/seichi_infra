resource "random_password" "influxdb_admin_password" {
  length  = 48
  special = true
}

resource "random_password" "influxdb_admin_token" {
  length  = 48
  special = true
}
