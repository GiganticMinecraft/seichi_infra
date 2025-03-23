resource "kubernetes_secret" "onp_minecraft_debug_secrets" {
  depends_on = [kubernetes_namespace.onp_seichi_debug_minecraft]

  metadata {
    name      = "mcserver--common--config-secrets"
    namespace = "seichi-debug-minecraft"
  }

  data = {
    DISCORDSRV_TOKEN      = var.minecraft__discordsrv_bot_token
    PROD_GAME_DB_PASSWORD = var.minecraft__prod_game_db__password
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

resource "kubernetes_secret" "onp_minecraft_prod_seichiassist_webhook_secrets" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "mcserver--seichiassist-webhook--config-secrets"
    namespace = "seichi-minecraft"
  }

  data = {
    SEICHIASSIST_S1_WEBHOOK_URL = var.minecraft__prod_s1_seichiassist_webhook_url
    SEICHIASSIST_S2_WEBHOOK_URL = var.minecraft__prod_s2_seichiassist_webhook_url
    SEICHIASSIST_S3_WEBHOOK_URL = var.minecraft__prod_s3_seichiassist_webhook_url
    SEICHIASSIST_S5_WEBHOOK_URL = var.minecraft__prod_s5_seichiassist_webhook_url
    SEICHIASSIST_S7_WEBHOOK_URL = var.minecraft__prod_s7_seichiassist_webhook_url
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

resource "kubernetes_secret" "argo_events_github_access_token" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "argo-events-github-access-token"
    namespace = "seichi-minecraft"
  }

  data = {
    # ref: https://github.com/argoproj/argo-events/blob/4636435578ae2396fa637e4ed44c2d2edbbec58b/examples/event-sources/github.yaml#L54
    ARGO_EVENTS_GITHUB_ACCESS_TOKEN = base64encode(var.argo_events_github_access_token)
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

resource "random_password" "minecraft__prod_mariadb_luckperms_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "minecraft__prod_mariadb_coreprotect_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "minecraft__prod_mariadb_litebans_password" {
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
    "root-password"        = random_password.minecraft__prod_mariadb_root_password.result
    "mcserver-password"    = random_password.minecraft__prod_mariadb_mcserver_password.result
    "luckperms-password"   = random_password.minecraft__prod_mariadb_luckperms_password.result
    "coreprotect-password" = random_password.minecraft__prod_mariadb_coreprotect_password.result
    "litebans-password"    = random_password.minecraft__prod_mariadb_litebans_password.result
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
        MINIO_ACCESS_SECRET: ${base64encode(var.minio_debug_access_secret)}
    EOS
    ]
  }

}

resource "helm_release" "onp_minecraft_pbs_credentials" {
  depends_on = [
    kubernetes_namespace.onp_seichi_debug_minecraft,
    kubernetes_namespace.onp_seichi_minecraft
  ]

  repository = "https://giganticminecraft.github.io/seichi_infra/"
  chart      = "raw-resources"
  name       = "onp-minecraft-pbs-credentials"
  namespace  = "kube-system"
  version    = "0.3.0"

  set_list {
    name = "manifests"
    value = [<<-EOS
      kind: ClusterSecret
      apiVersion: clustersecret.io/v1
      metadata:
        namespace: clustersecret
        name: pbs-credentials
      matchNamespace:
        - seichi-minecraft
        - seichi-debug-minecraft
        - minio
      data:
        user: ${var.proxmox_backup_client__user}
        host: ${var.proxmox_backup_client__host}
        datastore: ${var.proxmox_backup_client__datastore}
        password: ${var.proxmox_backup_client__password}
        fingerprint: ${var.proxmox_backup_client__fingerprint}
    EOS
    ]
  }

}
