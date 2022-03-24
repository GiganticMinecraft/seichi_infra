resource "kubernetes_secret" "debug_cloudflared_access_service_token" {
  depends_on = [
    kubernetes_namespace.seichi_debug_gateway,
  ]

  metadata {
    name      = "cloudflared-access-token"
    namespace = kubernetes_namespace.seichi_debug_gateway.metadata.name
  }

  data = {
    TUNNEL_SERVICE_TOKEN_ID     = cloudflare_access_service_token.debug_linode_to_onp.client_id
    TUNNEL_SERVICE_TOKEN_SECRET = cloudflare_access_service_token.debug_linode_to_onp.client_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "prod_cloudflared_access_service_token" {
  depends_on = [
    kubernetes_namespace.seichi_gateway,
  ]

  metadata {
    name      = "cloudflared-access-token"
    namespace = kubernetes_namespace.seichi_gateway.metadata.name
  }

  data = {
    TUNNEL_SERVICE_TOKEN_ID     = cloudflare_access_service_token.prod_linode_to_onp.client_id
    TUNNEL_SERVICE_TOKEN_SECRET = cloudflare_access_service_token.prod_linode_to_onp.client_secret
  }

  type = "Opaque"
}

