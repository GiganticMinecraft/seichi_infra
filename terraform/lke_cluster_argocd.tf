resource "helm_release" "lke_cluster_argocd" {
  depends_on = [kubernetes_namespace.argocd]

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  name       = "argocd"
  namespace  = "argocd"
  version    = "4.2.0"

  reset_values    = true
  recreate_pods   = true
  cleanup_on_fail = true

  values = [
    file("../proxy-kubernetes/argocd/argocd-helm-chart-values.yaml")
  ]
}
