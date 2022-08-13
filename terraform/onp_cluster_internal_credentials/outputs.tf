output "influxdb_admin_password" {
  value     = random_password.influxdb_admin_password
}

output "influxdb_admin_token" {
  value     = random_password.influxdb_admin_token
}
