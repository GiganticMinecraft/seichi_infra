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
    GAME_DB_PASSWORD = var.minecraft__production_game_db__password
  }

  type = "Opaque"
}

resource "kubernetes_secret" "onp_minecraft_one_day_to_reset_secrets" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft, kubernetes_namespace.onp_seichi_debug_minecraft]

  for_each = toset(["seichi-debug-minecraft", "seichi-minecraft"])

  metadata {
    name      = "mcserver--one-day-to-reset--config-secrets"
    namespace = each.value
  }

  data = {
    MORNING_GLORY_SEEDS_WEBHOOK_URL = var.minecraft__one_day_to_reset__morning_glory_seed_webhook_url
  }

  type = "Opaque"
}
