module "cluster_resources" {
  depends_on = [ null_resource.proxy_to_onp_k8s_api ]
  source = "./cluster_resources"

  cluster_host           = "https://${local.onp_kubernetes_tunnel_entry_host}:${local.onp_kubernetes_tunnel_entry_port}"
  cluster_ca_certificate = var.cluster_ca_certificate
  client_certificate     = var.client_certificate
  client_key             = var.client_key
}
