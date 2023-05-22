resource "kubernetes_secret" "onp_argocd_github_oauth_app_secret" {
  depends_on = [kubernetes_namespace.onp_argocd]

  metadata {
    name      = "argocd-github-oauth-app-secret"
    namespace = "argocd"
    labels = {
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
  depends_on = [kubernetes_namespace.onp_monitoring]

  metadata {
    name      = "grafana-github-oauth-app-secret"
    namespace = "monitoring"
  }

  data = {
    GF_AUTH_GITHUB_CLIENT_ID     = var.onp_k8s_grafana_github_oauth_app_id
    GF_AUTH_GITHUB_CLIENT_SECRET = var.onp_k8s_grafana_github_oauth_app_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "onp_synology_csi" {
  depends_on = [kubernetes_namespace.onp_synology_csi]

  metadata {
    name      = "client-info-secret"
    namespace = "synology-csi"
  }

  data = {
    "client-info.yml" = var.onp_k8s_synology_csi_config
  }

  type = "Opaque"
}

resource "kubernetes_secret" "cloudflared_tunnel_credential" {
  depends_on = [kubernetes_namespace.cloudflared_tunnel_exits]

  metadata {
    name      = "cloudflared-tunnel-credential"
    namespace = "cloudflared-tunnel-exits"
  }

  # cloudflared-tunnel Helm chart がこの形式の Secret を想定している。
  # どのようにこの Secret を Pod が利用しているかについては、
  # helm-charts/cloudflared-tunnel/deployment.yaml を参照のこと。
  data = {
    "TUNNEL_CREDENTIAL" = var.onp_k8s_cloudflared_tunnel_credential
  }

  type = "Opaque"
}

resource "kubernetes_secret" "minio_root_user" {
  depends_on = [kubernetes_namespace.minio]

  metadata {
    name      = "minio-root-user"
    namespace = "minio"
  }

  data = {
    "rootUser"     = "root"
    "rootPassword" = var.minio_root_password
  }

  type = "Opaque"
}

resource "kubernetes_secret" "minio_prod_access_secret" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "minio-access-secret"
    namespace = "seichi-minecraft"
  }

  data = {
    "MINIO_ACCESS_KEY"    = var.minio_prod_access_key
    "MINIO_ACCESS_SECRET" = var.minio_prod_access_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "minio_debug_access_secret" {
  depends_on = [kubernetes_namespace.onp_seichi_debug_minecraft]

  metadata {
    name      = "minio-access-secret"
    namespace = "seichi-debug-minecraft"
  }

  data = {
    "MINIO_ACCESS_KEY"    = var.minio_debug_access_key
    "MINIO_ACCESS_SECRET" = var.minio_debug_access_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "newrelic_credentials" {
  depends_on = [kubernetes_namespace.newrelic]

  metadata {
    name      = "newrelic-credentials"
    namespace = "newrelic"
  }

  # "deploy-key"は本来であれば他のkeyと命名規則を統一するべきだが
  # 20230314現在、helm-chart(pixie-operator-chart:0.0.35)でハードコードされているため命名を変更できない。
  # https://github.com/pixie-io/pixie/blob/release/operator/v0.0.35/k8s/operator/helm/values.yaml#L31-L33
  data = {
    "LicenseKey"  = var.newrelic_licensekey
    "PixieApiKey" = var.newrelic_pixie_api_key
    "deploy-key"  = var.newrelic_pixie_chart_deploy_key
  }

  type = "Opaque"
}
