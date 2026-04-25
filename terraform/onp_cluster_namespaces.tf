resource "kubernetes_namespace_v1" "onp_seichi_debug_gateway" {
  metadata {
    name = "seichi-debug-gateway"
  }
}

resource "kubernetes_namespace_v1" "onp_seichi_debug_minecraft" {
  metadata {
    name = "seichi-debug-minecraft"
  }
}

resource "kubernetes_namespace_v1" "onp_seichi_gateway" {
  metadata {
    name = "seichi-gateway"
    labels = {
      "goldilocks.fairwinds.com/enabled" = "true"
    }
  }
}

resource "kubernetes_namespace_v1" "onp_seichi_minecraft" {
  metadata {
    name = "seichi-minecraft"
    labels = {
      "goldilocks.fairwinds.com/enabled" = "true"
    }
  }
}

resource "kubernetes_namespace_v1" "onp_argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace_v1" "onp_argo" {
  metadata {
    name = "argo"
  }
}

resource "kubernetes_namespace_v1" "onp_monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "goldilocks.fairwinds.com/enabled" = "true"
    }
  }
}

resource "kubernetes_namespace_v1" "onp_synology_csi" {
  metadata {
    name = "synology-csi"
  }
}

resource "kubernetes_namespace_v1" "onp_democratic_csi" {
  metadata {
    name = "democratic-csi"
  }
}

resource "kubernetes_namespace_v1" "cloudflared_tunnel_exits" {
  metadata {
    name = "cloudflared-tunnel-exits"
  }
}

resource "kubernetes_namespace_v1" "garage" {
  metadata {
    name = "garage"
  }
}

resource "kubernetes_namespace_v1" "garage_admin" {
  metadata {
    name = "garage-admin"
  }
}

resource "kubernetes_namespace_v1" "kyverno" {
  metadata {
    name = "kyverno"
  }
}

resource "kubernetes_namespace_v1" "kubechecks" {
  metadata {
    name = "kubechecks"
  }
}
