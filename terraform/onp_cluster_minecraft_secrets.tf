resource "kubernetes_secret" "onp_minecraft_debug_secrets" {
  depends_on = [kubernetes_namespace.onp_seichi_debug_minecraft]

  metadata {
    name      = "mcserver--common--config-secrets"
    namespace = "seichi-debug-minecraft"
  }

  data = {
    DISCORDSRV_TOKEN = var.minecraft__discordsrv_bot_token
  }

  type = "Opaque"
}

resource "kubernetes_secret" "onp_minecraft_prod_secrets" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "mcserver--common--config-secrets"
    namespace = "seichi-minecraft"
  }

  data = {
    DISCORDSRV_TOKEN = var.minecraft__discordsrv_bot_token
    GAME_DB_PASSWORD = var.minecraft__prod_game_db__password
  }

  type = "Opaque"
}

resource "kubernetes_secret" "onp_minecraft_prod_one_day_to_reset_secrets" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "mcserver--one-day-to-reset--config-secrets"
    namespace = "seichi-minecraft"
  }

  data = {
    MORNING_GLORY_SEEDS_WEBHOOK_URL = var.minecraft__prod_one_day_to_reset__morning_glory_seed_webhook_url
  }

  type = "Opaque"
}

resource "kubernetes_secret" "onp_minecraft_prod_kagawa_secrets" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "mcserver--kagawa--config-secrets"
    namespace = "seichi-minecraft"
  }

  data = {
    MORNING_GLORY_SEEDS_WEBHOOK_URL = var.minecraft__prod_kagawa__morning_glory_seed_webhook_url
  }

  type = "Opaque"
}

resource "random_password" "minecraft__prod_mariadb_root_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "minecraft__prod_mariadb_mcserver_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret" "onp_minecraft_prod_mariadb_root_password" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "mariadb"
    namespace = "seichi-minecraft"
  }

  data = {
    "root-password"     = random_password.minecraft__prod_mariadb_root_password.result
    "mcserver-password" = random_password.minecraft__prod_mariadb_mcserver_password.result
  }

  type = "Opaque"
}

resource "random_password" "minecraft__debug_mariadb_root_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "minecraft__debug_mariadb_mcserver_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret" "onp_minecraft_debug_mariadb_root_password" {
  depends_on = [kubernetes_namespace.onp_seichi_debug_minecraft]

  metadata {
    name      = "mariadb"
    namespace = "seichi-debug-minecraft"
  }

  data = {
    "root-password"     = random_password.minecraft__debug_mariadb_root_password.result
    "mcserver-password" = random_password.minecraft__debug_mariadb_mcserver_password.result
  }

  type = "Opaque"
}

resource "helm_release" "onp_minecraft_debug_minio_secrets" { 
  depends_on = [kubernetes_namespace.onp_seichi_debug_minecraft]

  repository = "https://giganticminecraft.github.io/seichi_infra/"
  chart      = "raw-resources"
  name       = "seichi-debug-minecraft-minio-secrets"
  namespace  = "kube-system"
  version    = "0.3.0"

  set_list {
    name = "manifests"
    value = [<<-EOS
      kind: ClusterSecret
      apiVersion: clustersecret.io/v1
      metadata:
        namespace: clustersecret
        name: minio-secrets
      matchNamespace:
        - seichi-debug-minecraft-on-seichiassist-pr-*
      data:
        MINIO_ACCESS_KEY: ${base64encode(var.minio_debug_access_key)}
        MINIO_DEBUG_ACCESS_SECRET: ${base64encode(var.minio_debug_access_secret)}
    EOS
    ]
  }

}
