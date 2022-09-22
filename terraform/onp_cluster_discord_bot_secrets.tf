resource "kubernetes_secret" "onp_discord_bot_discord_spam_reporter_secrets" {
  depends_on = [kubernetes_namespace.onp_seichi_minecraft]

  metadata {
    name      = "discord-bot--discord-spam-reporter--config-secrets"
    namespace = "discord-bot"
  }

  data = {
    TOKEN = var.discord_bot__discord_spam_reporter__token
  }

  type = "Opaque"
}
