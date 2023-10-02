# 複数 Namespace 間で共有する秘匿値があるので、ClusterSecret controller を利用する
resource "helm_release" "onp_cluster_clustersecret" {
  depends_on = [kubernetes_namespace.onp_clustersecret]

  # https://github.com/zakkg3/ClusterSecret/tree/bab429d98b9da19debf97259fdba01211fa8dd43#using-the-official-helm-chart
  repository = "https://charts.clustersecret.io/"
  chart      = "cluster-secret"
  name       = "clustersecret"
  namespace  = "kube-system"
  version    = "0.2.1"

  reset_values    = true
  recreate_pods   = true
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

resource "random_password" "minecraft__prod_mariadb_monitoring_password" {
  length  = 16
  special = false // MariaDBのパスワードがぶっ壊れて困るので記号を含めない
}

resource "helm_release" "onp_minecraft_mariadb_monitoring_password" {
  depends_on = [helm_release.onp_cluster_clustersecret]

  # ClusterSecret controller も helm_release で入れている (onp_cluster_clustersecret) ため、
  # kubernetes_manifest リソースで ClusterSecret を入れようとすると、controller と ClusterSecret 両方を
  # (クラスタ再作成時等に) 作成する際に plan が失敗し、apply できなくなる。
  # https://github.com/hashicorp/terraform-provider-kubernetes/issues/1583
  #
  # これを回避するため、 values.yaml 内の manifest をそのまま apply するような Helm chart を作成し、
  # それを経由して ClusterSecret を作成する。こうすると、Terraform は ClusterSecret manifest の diff を取らずに
  # `onp_minecraft_mariadb_monitoring_password` に対応する Helm release が存在するかどうかだけを見るようになるので、
  # 上手くいく。
  repository = "https://giganticminecraft.github.io/seichi_infra/"
  chart      = "raw-resources"
  name       = "mariadb-monitoring-password-raw-resource"
  namespace  = "kube-system"
  version    = "0.2.0"

  set_sensitive {
    name = "manifests"
    value = [<<-EOS
      kind: ClusterSecret
      apiVersion: clustersecret.io/v1
      metadata:
        namespace: clustersecret
        name: mariadb-monitoring-password
      matchNamespace:
        - monitoring
        - seichi-minecraft
        - seichi-debug-minecraft-on-seichiassist-pr-*
      data:
        monitoring-password: ${base64encode(random_password.minecraft__prod_mariadb_monitoring_password.result)}
    EOS
    ]
  }
}
