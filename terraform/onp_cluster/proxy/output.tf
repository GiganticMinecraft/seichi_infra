output "cluster_host" {
  value = "https://${local.onp_kubernetes_tunnel_entry_host}:${local.onp_kubernetes_tunnel_entry_port}"
  depends_on= [ data.external.proxy_to_onp_k8s_api ]
}

output "dynamic_empty_str" {
  value = data.external.dynamic_proxy_to_onp_k8s_api.result.empty_str
}
