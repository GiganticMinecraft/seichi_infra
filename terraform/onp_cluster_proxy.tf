resource "null_resource" "proxy_to_onp_k8s_api" {
  // PlanでもApplyでも常にprovisionerを実行するため。
  // ref. https://github.com/hashicorp/terraform/issues/8266#issuecomment-454377049
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "${path.module}/sh/begin_tunnel_to_onp_k8s.sh \"${local.onp_kubernetes_tunnel_host}\" \"127.0.0.1:${local.onp_kubernetes_tunnel_entry_port}\""
    interpreter = ["bash", "-c"]
  }
}
