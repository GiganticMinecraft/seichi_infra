resource "helm_release" "lke_cluster_argocd" {
  provider = helm.lke_cluster

  depends_on = [kubernetes_namespace.argocd]

  # https://github.com/argoproj/argo-helm/releases/tag/argo-cd-4.2.2
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  name       = "argocd"
  namespace  = "argocd"
  version    = "4.6.4"

  reset_values    = true
  recreate_pods   = true
  cleanup_on_fail = true

  values = [
    file("../proxy-kubernetes/argocd-helm-chart-values.yaml")
  ]
}
