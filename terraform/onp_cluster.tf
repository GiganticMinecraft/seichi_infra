module "onp_cluster_resources" {
  source = "./onp_cluster/resources"

  argocd_github_oauth_app_secret  = var.onp_k8s_argocd_github_oauth_app_secret
  grafana_github_oauth_app_id     = var.onp_k8s_grafana_github_oauth_app_id
  grafana_github_oauth_app_secret = var.onp_k8s_grafana_github_oauth_app_secret
  synology_csi_config             = var.onp_k8s_synology_csi_config
}
