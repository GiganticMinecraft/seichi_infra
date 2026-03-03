# 複数 Namespace 間で共有する秘匿値があるので、kubernetes-replicator を利用する
resource "helm_release" "kubernetes_replicator" {
  repository = "https://helm.mittwald.de"
  chart      = "kubernetes-replicator"
  name       = "kubernetes-replicator"
  namespace  = "kube-system"
  version    = "2.12.3"

  reset_values    = true
  cleanup_on_fail = true
}

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

resource "kubernetes_secret" "onp_argocd_applicationset_controller_github_app_secret" {
  depends_on = [kubernetes_namespace.onp_argocd]

  metadata {
    name      = "argocd-applicationset-controller-github-app-secret"
    namespace = "argocd"
    labels = {
      # seichi_infra 向けのアクセストークンであると決め打ちする　必要に応じて repo-creds にするなどすると良い
      # repo-creds の詳細: https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#repository-credentials
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type                    = "git"
    url                     = "https://github.com/GiganticMinecraft/seichi_infra"
    githubAppID             = var.onp_k8s_argocd_applicationset_controller_github_app_id
    githubAppInstallationID = var.onp_k8s_argocd_applicationset_controller_github_app_installation_id
    githubAppPrivateKey     = var.onp_k8s_argocd_applicationset_controller_github_app_pem
  }

  type = "Opaque"
}

resource "kubernetes_secret" "onp_argocd_workflows_sso" {
  depends_on = [kubernetes_namespace.onp_argocd]

  metadata {
    name      = "argo-workflows-sso"
    namespace = "argocd"
  }

  data = {
    client-id     = "argo-workflows-sso"
    client-secret = var.onp_k8s_argo_workflows_sso_client_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "onp_argo_workflows_sso" {
  depends_on = [kubernetes_namespace.onp_argo]

  metadata {
    name      = "argo-workflows-sso"
    namespace = "argo"
  }

  data = {
    client-id     = "argo-workflows-sso"
    client-secret = var.onp_k8s_argo_workflows_sso_client_secret
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

resource "kubernetes_secret" "onp_democratic_csi_sc_truenas_03" {
  depends_on = [kubernetes_namespace.onp_democratic_csi]

  metadata {
    name      = "democratic-csi-driver-config-sc-truenas-03"
    namespace = "democratic-csi"
  }

  data = {
    # democratic-csi はこのキー名でマウントされたファイルを読む
    # ref. https://github.com/democratic-csi/charts/blob/master/stable/democratic-csi/templates/controller.yaml
    "driver-config-file.yaml" = var.onp_k8s_democratic_csi_sc_truenas_03_driver_config
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

# Garage S3-compatible object storage credentials
resource "kubernetes_secret" "garage_loki_credentials" {
  depends_on = [kubernetes_namespace.onp_monitoring]

  metadata {
    name      = "garage-loki-credentials"
    namespace = "monitoring"
  }

  data = {
    "AWS_ACCESS_KEY_ID"     = var.garage_loki_access_key_id
    "AWS_SECRET_ACCESS_KEY" = var.garage_loki_secret_access_key
  }

  type = "Opaque"
}

resource "kubernetes_secret" "garage_thanos_credentials" {
  depends_on = [kubernetes_namespace.onp_monitoring]

  metadata {
    name      = "garage-thanos-credentials"
    namespace = "monitoring"
  }

  data = {
    # Thanos sidecar は objstore.yml キーで S3 設定を読み込む
    "objstore.yml" = yamlencode({
      type = "S3"
      config = {
        bucket     = "thanos"
        endpoint   = "garage.garage.svc.cluster.local:3900"
        region     = "seichi-cloud"
        access_key = var.garage_thanos_access_key_id
        secret_key = var.garage_thanos_secret_access_key
        insecure   = true
        http_config = {
          idle_conn_timeout = "90s"
        }
      }
    })
  }

  type = "Opaque"
}

resource "kubernetes_secret" "garage_seichi_minecraft_credentials" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "garage-s3-credentials"
    namespace = "seichi-minecraft"
    annotations = {
      "replicator.v1.mittwald.de/replicate-to" = "seichi-debug-minecraft,seichi-debug-minecraft-on-seichiassist-pr-.*"
    }
  }

  data = {
    "AWS_ACCESS_KEY_ID"     = var.garage_seichi_minecraft_access_key_id
    "AWS_SECRET_ACCESS_KEY" = var.garage_seichi_minecraft_secret_access_key
  }

  type = "Opaque"
}

resource "kubernetes_secret" "garage_backup_s3_credentials" {
  depends_on = [kubernetes_namespace.garage]

  metadata {
    name      = "garage-backup-s3-credentials"
    namespace = "garage"
  }

  data = {
    "AWS_ACCESS_KEY_ID"     = var.garage_backup_access_key_id
    "AWS_SECRET_ACCESS_KEY" = var.garage_backup_secret_access_key
  }

  type = "Opaque"
}

# Garage Admin API token (shared between Garage daemon and Admin Console)
resource "kubernetes_secret" "garage_admin_api_token" {
  depends_on = [kubernetes_namespace.garage]

  metadata {
    name      = "garage-admin-api-token"
    namespace = "garage"
  }

  data = {
    "token" = var.garage_admin_api_token
  }

  type = "Opaque"
}

# Garage Admin Console secrets
resource "kubernetes_secret" "garage_admin_github_oauth" {
  depends_on = [kubernetes_namespace.garage_admin]

  metadata {
    name      = "garage-admin-github-oauth"
    namespace = "garage-admin"
  }

  data = {
    "GITHUB_CLIENT_ID"     = var.garage_admin_github_client_id
    "GITHUB_CLIENT_SECRET" = var.garage_admin_github_client_secret
    "SESSION_SECRET"       = var.garage_admin_session_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "garage_admin_token" {
  depends_on = [kubernetes_namespace.garage_admin]

  metadata {
    name      = "garage-admin-token"
    namespace = "garage-admin"
  }

  data = {
    "GARAGE_ADMIN_TOKEN" = var.garage_admin_api_token
  }

  type = "Opaque"
}

resource "kubernetes_secret" "garage_admin_s3" {
  depends_on = [kubernetes_namespace.garage_admin]

  metadata {
    name      = "garage-admin-s3"
    namespace = "garage-admin"
  }

  data = {
    "AWS_ACCESS_KEY_ID"     = var.garage_admin_s3_access_key_id
    "AWS_SECRET_ACCESS_KEY" = var.garage_admin_s3_secret_access_key
  }

  type = "Opaque"
}

# TrueNAS Exporter API key
resource "kubernetes_secret" "truenas_exporter_api_key" {
  depends_on = [kubernetes_namespace.onp_monitoring]

  metadata {
    name      = "truenas-exporter-api-key"
    namespace = "monitoring"
  }

  data = {
    TRUENAS_API_KEY = var.truenas_exporter_api_key
  }

  type = "Opaque"
}

resource "random_password" "minecraft__prod_mariadb_pr_review_password" {
  length  = 16
  special = false // MariaDBのパスワードがぶっ壊れて困るので記号を含めない
}

resource "random_password" "minecraft__prod_mariadb_monitoring_password" {
  length  = 16
  special = false // MariaDBのパスワードがぶっ壊れて困るので記号を含めない
}

# mariadb-monitoring-password: seichi-minecraft に配置し、monitoring と PR namespaces に複製
resource "kubernetes_secret" "mariadb_monitoring_password" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "mariadb-monitoring-password"
    namespace = "seichi-minecraft"
    annotations = {
      "replicator.v1.mittwald.de/replicate-to" = "monitoring,seichi-debug-minecraft-on-seichiassist-pr-.*"
    }
  }

  data = {
    "monitoring-password" = random_password.minecraft__prod_mariadb_monitoring_password.result
  }

  type = "Opaque"
}

# mariadb-pr-review-password: kube-system に配置し、PR namespaces に複製
resource "kubernetes_secret" "mariadb_pr_review_password" {
  metadata {
    name      = "mariadb-pr-review-password"
    namespace = "kube-system"
    annotations = {
      "replicator.v1.mittwald.de/replicate-to" = "seichi-minecraft,seichi-debug-minecraft-on-seichiassist-pr-.*"
    }
  }

  data = {
    "root-password"         = ""
    "mcserver-password"     = ""
    "prod-mariadb-password" = random_password.minecraft__prod_mariadb_pr_review_password.result
  }

  type = "Opaque"
}

resource "kubernetes_secret" "idea_reaction_discord_token" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "idea-reaction-discord-token"
    namespace = "seichi-minecraft"
  }

  data = {
    IDEA_REACTION_DISCORD_TOKEN = var.discord_bot__idea_reaction__discord_token
  }
}

resource "kubernetes_secret" "idea_reaction_redmine_api_key" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "idea-reaction-redmine-api-key"
    namespace = "seichi-minecraft"
  }

  data = {
    IDEA_REACTION_REDMINE_API_KEY = var.discord_bot__idea_reaction__redmine_api_key
  }
}

resource "kubernetes_secret" "babyrite_discord_token" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "babyrite-discord-token"
    namespace = "seichi-minecraft"
  }

  data = {
    BABYRITE_DISCORD_TOKEN = var.discord_bot__babyrite__discord_token
  }
}

