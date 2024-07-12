resource "helm_release" "onp_cluster_argocd" {
  # https://github.com/argoproj/argo-helm/releases/tag/argo-cd-7.2.1
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  name       = "argocd"
  namespace  = "argocd"
  version    = "7.3.6"

  reset_values    = true
  recreate_pods   = true
  cleanup_on_fail = true

  values = [
    # terraform working directory からの相対パス
    file("../seichi-onp-k8s/manifests/seichi-kubernetes/argocd-helm-chart-values.yaml")
  ]
}

resource "helm_release" "onp_cluster_argo_apps" {
  # https://github.com/argoproj/argo-helm/releases/tag/argocd-apps-2.0.0
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  name       = "argocd-apps"
  namespace  = "argocd"
  version    = "2.0.0"

  reset_values    = true
  recreate_pods   = true
  cleanup_on_fail = true

  values = [
    # terraform working directory からの相対パス
    file("../seichi-onp-k8s/manifests/seichi-kubernetes/argocd-apps-helm-chart-values.yaml")
  ]
}
