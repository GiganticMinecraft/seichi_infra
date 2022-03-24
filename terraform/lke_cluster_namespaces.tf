resource "kubernetes_namespace" "seichi_debug_gateway" {
  metadata {
    name = "seichi-debug-gateway"
  }
}

resource "kubernetes_namespace" "seichi_gateway" {
  metadata {
    name = "seichi-gateway"
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "cluster_wide_apps" {
  metadata {
    name = "cluster-wide-apps"
  }
}
