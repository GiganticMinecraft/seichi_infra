resource "kubernetes_namespace" "onp_seichi_debug_gateway" {
  metadata {
    name = "seichi-debug-gateway"
  }
}

resource "kubernetes_namespace" "onp_seichi_debug_minecraft" {
  metadata {
    name = "seichi-debug-minecraft"
  }
}

resource "kubernetes_namespace" "onp_seichi_gateway" {
  metadata {
    name = "seichi-gateway"
  }
}

resource "kubernetes_namespace" "onp_seichi_minecraft" {
  metadata {
    name = "seichi-minecraft"
  }
}

resource "kubernetes_namespace" "onp_argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "onp_monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "onp_synology_csi" {
  metadata {
    name = "synology-csi"
  }
}

resource "kubernetes_namespace" "cloudflared_tunnel_exits" {
  metadata {
    name = "cloudflared-tunnel-exits"
  }
}

resource "kubernetes_namespace" "onp_sentry" {
  metadata {
    name = "sentry"
  }
}

resource "kubernetes_namespace" "minio" {
  metadata {
    name = "minio"
  }
}
