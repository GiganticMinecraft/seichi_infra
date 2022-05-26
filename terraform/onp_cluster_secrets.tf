resource "kubernetes_secret" "onp_argocd_github_oauth_app_secret" {
  provider = kubernetes.onp_cluster

  depends_on = [ null_resource.proxy_to_onp_k8s_api, kubernetes_namespace.onp_argocd ]

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
    ARGOCD_GITHUB_OAUTH_APP_SECRET = var.onp_k8s_argocd_github_oauth_app_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "onp_grafana_github_oauth_app_secret" {
  provider = kubernetes.onp_cluster

  depends_on = [ null_resource.proxy_to_onp_k8s_api, kubernetes_namespace.onp_monitoring ]

  metadata {
    name      = "grafana-github-oauth-app-secret"
    namespace = "monitoring"
  }

  data = {
    ARGOCD_GITHUB_OAUTH_APP_SECRET = var.onp_k8s_grafana_github_oauth_app_secret
  }

  type = "Opaque"
}
