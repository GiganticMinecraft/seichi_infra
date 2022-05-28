resource "kubernetes_secret" "onp_logdna_agent_ingestion_key" {
  # name と data の指定は LOGDNA_INGESTION_KEY の参照指定による
  # https://github.com/logdna/logdna-agent-v2/blob/442810f18f4ea44c71bedff01c12795223b0e41e/k8s/agent-resources.yaml#L114-L118

  metadata {
    namespace = "cluster-wide-apps"
    name      = "logdna-agent-key"
  }

  data = {
    "logdna-agent-key" = "INVALID_KEY"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "onp_argocd_github_oauth_app_secret" {
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
  metadata {
    name      = "client-info-secret"
    namespace = "synology-csi"
  }

  data = {
    "client-info.yml" = var.synology_csi_config
  }

  type = "Opaque"
}
