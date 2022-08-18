resource "helm_release" "onp_cluster_argocd" {
  # https://github.com/argoproj/argo-helm/releases/tag/argo-cd-4.2.2
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  name       = "argocd"
  namespace  = "argocd"
  version    = "4.10.7"

  reset_values    = true
  recreate_pods   = true
  cleanup_on_fail = true

  values = [
    # terraform working directory からの相対パス
    file("../seichi-onp-k8s/manifests/seichi-kubernetes/argocd-helm-chart-values.yaml")
  ]
}
