output "cluster_host" {
  value = "https://${local.onp_kubernetes_tunnel_entry_host}:${local.onp_kubernetes_tunnel_entry_port}"
  depends_on = [ null_resource.proxy_to_onp_k8s_api ]
}
