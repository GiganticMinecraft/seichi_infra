resource "kubernetes_secret" "onp_minecraft_secrets" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft, kubernetes_namespace.onp_seichi_debug_minecraft]

  for_each = toset(["seichi-debug-minecraft", "seichi-minecraft"])

  metadata {
    name      = "mcserver--common--config-secrets"
    namespace = each.value
  }

  data = {
    # TODO: put real data from variable
    DISCORDSRV_TOKEN = "INVALID_TOKEN"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "onp_minecraft_secrets" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft, kubernetes_namespace.onp_seichi_debug_minecraft]

  for_each = toset(["seichi-debug-minecraft", "seichi-minecraft"])

  metadata {
    name      = "mcserver--one-day-to-reset--config-secrets"
    namespace = each.value
  }

  data = {
    # TODO: put real data from variable
    MORNING_GLORY_SEEDS_WEBHOOK_URL = "https://discord.com/api/webhooks/886923395407679498/INVALID_ENDPOINT"
  }

  type = "Opaque"
}
