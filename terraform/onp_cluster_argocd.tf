resource "helm_release" "onp_cluster_argocd" {
  provider = helm.onp_cluster

  depends_on = [ kubernetes_namespace.onp_argocd ]

  # https://github.com/argoproj/argo-helm/releases/tag/argo-cd-4.2.2
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  name       = "argocd"
  namespace  = "argocd"
  version    = "4.7.0"

  reset_values    = true
  recreate_pods   = true
  cleanup_on_fail = true

  values = [
    file("../seichi-onp-k8s/manifests/seichi-kubernetes/argocd-helm-chart-values.yaml")
  ]
}
