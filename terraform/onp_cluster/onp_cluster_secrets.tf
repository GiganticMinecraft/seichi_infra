# TODO: このリソースを削除する
#       Terraform Cloud から GHA への移行をするために一時的に置きっぱなしにしているだけなので、移行が終わったら消す
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

resource "kubernetes_secret" "cloudflared_tunnel_credential" {
  depends_on = [ kubernetes_namespace.cloudflared_tunnel_exits ]

  metadata {
    name      = "cloudflared-tunnel-credential"
    namespace = "cloudflared-tunnel-exits"
  }

  # cloudflared-tunnel Helm chart がこの形式の Secret を想定している。
  # どのようにこの Secret を Pod が利用しているかについては、
  # helm-charts/cloudflared-tunnel/deployment.yaml を参照のこと。
  data = {
    "TUNNEL_CREDENTIAL" = var.cloudflared_tunnel_credential
  }

  type = "Opaque"
}

resource "kubernetes_secret" "minio_root_user" {
  depends_on = [ kubernetes_namespace.minio ]

  metadata {
    name      = "minio-root-user"
    namespace = "minio"
  }

  data = {
    "rootUser"     = var.minio_root_user
    "rootPassword" = var.minio_root_password
  }

  type = "Opaque"
}
