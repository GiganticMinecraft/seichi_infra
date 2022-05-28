module "onp_cluster" {
  # プロキシを張るために *.local-tunnels.seichi.click が 127.0.0.1 に向いている必要がある
  depends_on = [ cloudflare_record.local_tunnels ]

  source = "./onp_cluster"

  cluster_ca_certificate = local.onp_kubernetes_cluster_ca_certificate
  client_certificate     = local.onp_kubernetes_client_certificate
  client_key             = local.onp_kubernetes_client_key
}
