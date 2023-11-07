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
    DISCORDSRV_TOKEN            = var.minecraft__discordsrv_bot_token
    GAME_DB_PASSWORD            = var.minecraft__prod_game_db__password
    IDEA_REACTION_DISCORD_TOKEN = var.minecraft__idea_reaction_discord_token
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
