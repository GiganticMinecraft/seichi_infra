output "influxdb_admin_password" {
  value     = random_password.influxdb_admin_password
  sensitive = true
}

output "influxdb_admin_token" {
  value     = random_password.influxdb_admin_token
  sensitive = true
}
