resource "kubernetes_secret" "cloudflared_tunnel_credential" {
  depends_on = [kubernetes_namespace.cluster_wide_apps]

  metadata {
    name      = "cloudflared-tunnel-credential"
    namespace = "cluster-wide-apps"
  }

  data = {
    TUNNEL_CREDENTIAL = var.lke_k8s_cloudflare_argo_tunnel_credential
  }

  type = "Opaque"
}

resource "kubernetes_secret" "logdna_agent_ingestion_key" {
  depends_on = [kubernetes_namespace.cluster_wide_apps]

  metadata {
    name      = "logdna-agent-ingestion-key"
    namespace = "cluster-wide-apps"
  }

  data = {
    TUNNEL_CREDENTIAL = var.lke_k8s_logdna_agent_ingestion_key
  }

  type = "Opaque"
}

resource "kubernetes_secret" "argocd_github_oauth_app_secret" {
  depends_on = [kubernetes_namespace.argocd]

  metadata {
    name      = "argocd-github-oauth-app-secret"
    namespace = "argocd"
    labels    = {
      # これが必要っぽい
      # https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#alternative
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    ARGOCD_GITHUB_OAUTH_APP_SECRET = var.lke_k8s_argocd_github_oauth_app_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "debug_cloudflared_access_service_token" {
  depends_on = [kubernetes_namespace.seichi_debug_gateway]

  metadata {
    name      = "cloudflared-access-token"
    namespace = "seichi-debug-gateway"
  }

  data = {
    TUNNEL_SERVICE_TOKEN_ID     = cloudflare_access_service_token.debug_linode_to_onp.client_id
    TUNNEL_SERVICE_TOKEN_SECRET = cloudflare_access_service_token.debug_linode_to_onp.client_secret
  }

  type = "Opaque"
}

resource "kubernetes_secret" "prod_cloudflared_access_service_token" {
  depends_on = [kubernetes_namespace.seichi_gateway]

  metadata {
    name      = "cloudflared-access-token"
    namespace = "seichi-gateway"
  }

  data = {
    TUNNEL_SERVICE_TOKEN_ID     = cloudflare_access_service_token.prod_linode_to_onp.client_id
    TUNNEL_SERVICE_TOKEN_SECRET = cloudflare_access_service_token.prod_linode_to_onp.client_secret
  }

  type = "Opaque"
}
