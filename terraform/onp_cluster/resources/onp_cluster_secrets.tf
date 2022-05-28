resource "kubernetes_secret" "onp_argocd_github_oauth_app_secret" {
  depends_on = [ kubernetes_namespace.onp_argocd ]

  metadata {
    name      = "argocd-github-oauth-app-secret"
    namespace = "argocd"
    labels    = {
      # これが必要っぽい
      # https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#alternative
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    ARGOCD_GITHUB_OAUTH_APP_SECRET = var.argocd_github_oauth_app_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "onp_grafana_github_oauth_app_secret" {
  depends_on = [ kubernetes_namespace.onp_monitoring ]

  metadata {
    name      = "grafana-github-oauth-app-secret"
    namespace = "monitoring"
  }

  data = {
    GF_AUTH_GITHUB_CLIENT_ID = var.grafana_github_oauth_app_id
    GF_AUTH_GITHUB_CLIENT_SECRET = var.grafana_github_oauth_app_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "onp_synology_csi" {
  depends_on = [ kubernetes_namespace.onp_synology_csi ]

  metadata {
    name      = "client-info-secret"
    namespace = "synology-csi"
  }

  data = {
    "client-info.yml" = var.synology_csi_config
  }

  type = "Opaque"
}
