resource "kubernetes_namespace" "onp_seichi_debug_gateway" {
  depends_on = [ null_resource.proxy_to_onp_k8s_api ]

  provider = kubernetes.onp_cluster

  metadata {
    name = "seichi-debug-gateway"
  }
}

resource "kubernetes_namespace" "onp_seichi_gateway" {
  depends_on = [ null_resource.proxy_to_onp_k8s_api ]

  provider = kubernetes.onp_cluster

  metadata {
    name = "seichi-gateway"
  }
}

resource "kubernetes_namespace" "onp_argocd" {
  depends_on = [ null_resource.proxy_to_onp_k8s_api ]

  provider = kubernetes.onp_cluster

  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "onp_cluster_wide_apps" {
  depends_on = [ null_resource.proxy_to_onp_k8s_api ]

  provider = kubernetes.onp_cluster

  metadata {
    name = "cluster-wide-apps"
  }
}
