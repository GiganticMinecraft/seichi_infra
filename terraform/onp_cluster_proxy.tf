locals {
  onp_kubernetes_tunnel_entry_url = "127.0.0.1:${local.onp_kubernetes_tunnel_entry_port}"
  tunnel_cmd = join(
    " ",
    [
      "\"${path.module}/sh/begin_cloudflared_tunnel.sh\"",
      "\"${local.onp_kubernetes_tunnel_host}\"",
      "\"${local.onp_kubernetes_tunnel_entry_url}\""
    ]
  )
}

# HACK:
#   Terraform Cloud での実行時には、
#     - external.proxy_to_onp_k8s_api は plan 時に実行される。
#       しかし、このリソースの実行結果(external program protocolで吐かれるMap)は apply 時に「静的に持ち越される」ため、
#       スクリプトは apply 時には実行されない
#     - null_resource.proxy_to_onp_k8s_api は plan 時には実行 (create) されず、 apply 時に常に recreate される
#
#   という動作が観測できた。
#   このため、plan 時にも apply 時にもトンネルを張るために data / resource の組を定義している。
#
#   もしこれらの data / resource 対を自前providerに置き換える場合は、
#   plan/applyの両フェーズでトンネルを張るような物である必要がある。

data "external" "proxy_to_onp_k8s_api" {
  depends_on = [ cloudflare_record.local_tunnels ]
  program = [ "bash", "-c", local.tunnel_cmd ]
}

resource "null_resource" "proxy_to_onp_k8s_api" {
  depends_on = [ resources.cloudflare_record.local_tunnels, data.external.proxy_to_onp_k8s_api ]

  // Apply時に常にprovisionerを実行するため。
  // ref. https://github.com/hashicorp/terraform/issues/8266#issuecomment-454377049
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command     = local.tunnel_cmd
    interpreter = ["bash", "-c"]
  }
}
