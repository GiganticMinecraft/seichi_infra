resource "kubernetes_namespace" "onp_seichi_debug_gateway" {
  provider = kubernetes.onp_cluster

  metadata {
    name = "seichi-debug-gateway"
  }
}

resource "kubernetes_namespace" "onp_seichi_gateway" {
  provider = kubernetes.onp_cluster

  metadata {
    name = "seichi-gateway"
  }
}

resource "kubernetes_namespace" "onp_argocd" {
  provider = kubernetes.onp_cluster

  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "onp_cluster_wide_apps" {
  provider = kubernetes.onp_cluster

  metadata {
    name = "cluster-wide-apps"
  }
}
