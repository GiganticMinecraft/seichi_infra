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
