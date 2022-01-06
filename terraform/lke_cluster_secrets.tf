resource "kubernetes_secret" "debug_cloudflared_access_service_token" {
  metadata {
    name      = "cloudflared-access-token"
    namespace = "haproxy-debug-gw"
  }

  data = {
    TUNNEL_SERVICE_TOKEN_ID     = cloudflare_access_service_token.debug_linode_to_onp.client_id
    TUNNEL_SERVICE_TOKEN_SECRET = cloudflare_access_service_token.debug_linode_to_onp.client_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "prod_cloudflared_access_service_token" {
  metadata {
    name      = "cloudflared-access-token"
    namespace = "haproxy-gw"
  }

  data = {
    TUNNEL_SERVICE_TOKEN_ID     = cloudflare_access_service_token.prod_linode_to_onp.client_id
    TUNNEL_SERVICE_TOKEN_SECRET = cloudflare_access_service_token.prod_linode_to_onp.client_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "kube-system_cloudflare_api_key" {
  metadata {
    name      = "cloudflare-secret"
    namespace = "kube-system"
  }

  data = {
    CLOUDFLARE_EMAIL   = var.cloudflare_email
    CLOUDFLARE_API_KEY = var.cloudflare_api_key
  }

  type = "Opaque"
}
