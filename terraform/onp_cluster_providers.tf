# トンネルが貼れるポートを取得する
data "external" "port_for_cloudflare_tunnel_to_onp_k8s_api" {
  program = [
    "bash",
    "${path.module}/sh/pick_free_port.sh"
  ]
}

locals {
  # トンネルの接続先のドメイン
  onp_kubernetes_tunnel_host       = "k8s-api.onp-k8s.admin.seichi.click"

  # APIエンドポイントが最終的に露出されるべきドメイン。
  # このドメインは cloudflare_dns_records.tf の設定により、127.0.0.1 (localhost) に向いている。
  onp_kubernetes_tunnel_entry_host = "k8s-api.onp-k8s.admin.local-tunnels.seichi.click"
  onp_kubernetes_tunnel_entry_port = data.external.port_for_cloudflare_tunnel_to_onp_k8s_api.result.port

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
#   また、各k8sリソースが null_resource.proxy_to_onp_k8s_api に依存するのみでは**不十分である**。
#   Resource create / update 時は確かにそれで良いのだが、 delete のみ行う場合は、
#   null_resource.proxy_to_onp_k8s_api の recreation を待つ必要が無いため、トンネルが張られるより前に
#   削除を行おうとして、失敗する (詳細: https://github.com/GiganticMinecraft/seichi_infra/issues/328)。
#
#   よって、本質的に、「data / resource 対のどちらにも provider 自体が依存する」というのが
#   Terraformの動作自体をラップせずにトンネル越しにCRUD操作を実現する必要条件となる。
#
#   null_resource.proxy_to_onp_k8s_api は external.proxy_to_onp_k8s_api に依存しているため、
#   provider が null_resource.proxy_to_onp_k8s_api に依存するというのを Terraform に伝えればよい。

data "external" "proxy_to_onp_k8s_api" {
  depends_on = [ cloudflare_record.local_tunnels ]
  program = [ "bash", "-c", local.tunnel_cmd ]
}

resource "null_resource" "proxy_to_onp_k8s_api" {
  depends_on = [ cloudflare_record.local_tunnels, data.external.proxy_to_onp_k8s_api ]

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

locals {
  onp_kubernetes_cluster_host = "https://${local.onp_kubernetes_tunnel_entry_host}:${local.onp_kubernetes_tunnel_entry_port}"
}

provider "kubernetes" {
  depends_on = [ null_resource.proxy_to_onp_k8s_api ]

  alias = "onp_cluster"

  host                   = local.onp_kubernetes_cluster_host
  cluster_ca_certificate = local.onp_kubernetes_cluster_ca_certificate
  client_certificate     = local.onp_kubernetes_client_certificate
  client_key             = local.onp_kubernetes_client_key
}

provider "helm" {
  depends_on = [ null_resource.proxy_to_onp_k8s_api ]

  alias = "onp_cluster"

  kubernetes {
    host                   = local.onp_kubernetes_cluster_host
    cluster_ca_certificate = local.onp_kubernetes_cluster_ca_certificate
    client_certificate     = local.onp_kubernetes_client_certificate
    client_key             = local.onp_kubernetes_client_key
  }
}
