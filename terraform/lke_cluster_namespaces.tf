resource "kubernetes_namespace" "seichi_debug_gateway" {
  provider = kubernetes.lke_cluster

  metadata {
    name = "seichi-debug-gateway"
  }
}

resource "kubernetes_namespace" "seichi_gateway" {
  provider = kubernetes.lke_cluster

  metadata {
    name = "seichi-gateway"
  }
}

resource "kubernetes_namespace" "argocd" {
  provider = kubernetes.lke_cluster

  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "cluster_wide_apps" {
  provider = kubernetes.lke_cluster

  metadata {
    name = "cluster-wide-apps"
  }
}
