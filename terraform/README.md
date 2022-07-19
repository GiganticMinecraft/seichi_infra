# `seichi_infra` / `terraform`

Terraform で管理しているインフラの設定をまとめているディレクトリです。

## 管理しているリソース

2022/06/04現在、Terraform 管理下にある設定および定義は以下の通りです。ドキュメントは古くなっている可能性があるため、詳細はこのディレクトリ内にある各 `.tf` ファイルを参照してください。

 - GitHub
   - Teamsの定義
   - Repositoryの設定
 - Cloudflare
   - Access Apllicationのアクセス制御設定
   - Edge証明書の設定
   - Page ruleの設定
   - DNS設定
 - オンプレ環境の k8s クラスタ上の一部リソースの管理
   - 現時点では `Secret` リソースと `Namespace` リソースだけ Terraform で管理している

## GitHub Actions + Terraform Cloud での実行

当リポジトリでは、 Terraform の実行(`plan` / `apply`)を Terraform Cloud に完全に移譲せずに、
 - 実行は GitHub Actions ワークフローにて
 - Terraform の実インフラに関する知識が集約されている `.tfstate` の保存及び同期を Terraform Cloud にて

行っています。

次の二つのサブセクションでは、何故すべてを Terraform Cloud で実行せずにこのような構成が行われているか、についての理由を述べます。

### 背景にある問題

整地鯖では、万が一Kubernetesクラスタが破損状態に陥って再構築する必要があっても
問題なく各種シークレット等をクラスタに再度流し込めるよう、Terraformが走る環境にシークレット値を登録しておいて、
[Kubernetes providerの `kubernetes_secret` リソース](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret)でシークレット値をクラスタに注入しています。

ところで、クラスタがオンプレ環境に設置してあるため、以下のような要件が存在します：
 - TerraformがAPIサーバーに HTTPS で到達できなければならない
 - しかしながら、ルーターにポート解放の設定をしてルーターのグローバルIPアドレスでアクセスする、という構造にはしたくない
   - ルーターの設定変更は現状 unchama しかできないので、そもそもその設定にあまり依存したくない
   - 整地鯖への接続経路は極力プロキシを通して、グローバルIPアドレスを秘匿できるようにしておきたい
     - DDoS攻撃などで帯域が食いつぶされて、管理画面に unchama 以外到達できない、という状況を避けたいため

この一見矛盾するように思える要件は、実は
 - Cloudflare Tunnel等のingress設定をどこにも行う必要が無いプロキシを利用し、
 - CloudflareがIPを公開しないことを信頼する
 
ことで解決できます。
 
しかしながら、kubectl はクライアント証明書によってAPIサーバーに対して認証/接続を行うことになっています。
よって、Terraform の Kubernetes provider を HTTPS で API サーバーに繋げるためには、サーバーが、
  1. 「クラスタのCA証明書によって署名された」、「APIサーバーのアドレスに対する証明書」を、
  1. 「クラスタのCA証明書によって署名された」、「クライアントの同一性を証明する証明書」と
  1. 「トランスポート層のプロトコル(TLS handshake)で」

クライアントと交換する必要があります(このうち、「クラスタのCA証明書」と、「それで署名されたクライアント証明書の鍵ペア」はクラスタセットアップ時に `.kubeconfig` に書き出すことができます。これら二つの値を Terraform variable(後述) に入力して Terraform を実行することで、Terraform が Kubernetes provider にこれらの接続情報を入力できるようになっています)。

Cloudflare Tunnel を利用する場合、Cloudflare のサーバーに接続しに行くクライアントは、(Cloudflare Enterprise Planを利用していない限りは) Cloudflare によって署名された edge certificate であり、上記のような鍵交換が実現することはありません。

### 上記問題の解決アプローチについて

上記の問題を解決するために、まず

 - クラスタの証明局が発行する API サーバーの証明書の SAN (Subject Alternative Names) に
   `k8s-api.onp-k8s.admin.local-tunnels.seichi.click` を入れるようにする
 - Cloudflare の DNS 設定により、`k8s-api.onp-k8s.admin.local-tunnels.seichi.click` が
   `127.0.0.1` (ループバックアドレス) を向くようにする

の二つの設定を行っています。

これらの設定を行ったうえで、Terraform を実行するマシン上で `cloudflared access` によりトンネルへの入口を用意し、
Kubernetes API サーバーまで TCP 通信ができるようにすると、`k8s-api.onp-k8s.admin.local-tunnels.seichi.click:<PORT>` を kubectl のホストに指定するだけで、クライアント証明で認証された HTTPS 通信を API サーバーと行えるようになります。

このセットアップの概要は以下の図にまとめられています。

![クラスタAPIを外部公開する仕組みの構成図](../seichi-onp-k8s/cluster-boot-up/docs/diagrams/cluster-api-exposure.drawio.svg)

このセットアップを実現するためには、 `terraform apply` 等を実行するマシン上で `cloudflared access` によるトンネルが作成される必要があります。Terraform Cloud 上ではそのような設定 (`apply` / `plan` の前後で追加のコマンドを走らせるといった指定) は 2022/06/04 現在では不可能であるため、 GitHub Actions ワークフロー上で実現し、Terraform Cloudには `.tfstate` の管理だけを任せています。

## GitHub Actions から渡される Terraform variableについて

GitHub Actions ワークフロー上で Terraform を実行する都合上、 Terraform の variable は GitHub Actions Secret を元に生成したものを環境変数経由で `terraform` CLI に流し込んでいます。

これは以下に示す手順で行っており、 Terraform CLI には小文字化された変数しか variable として入力されないため、**Terraform variableを新規に追加する場合は、すべて小文字のスネークケースにて定義するよう注意してください**。

### GitHub Actions Secret を環境変数に変換する手順

Terraform は `TF_VAR_*` の形をした環境変数を用いて variable への入力を作成します([参考](https://www.terraform.io/language/values/variables#environment-variables))。GitHub Actions Secret と環境変数の間には

 - GitHub Actions Secret は case insensitive
 - 環境変数、及び Terraform variable は case sensitive

という差異があります。

そのため、`TF_VAR_(\w+)` の形をした GitHub Actions Secret のキーとその値のペアをすべて列挙したうえで、各ペアについて、
 1. キー `TF_VAR_(\w+)` から `$1` の部分を取り出し、`$1` を**小文字化したものを** `lower_var_name` とする
 1. `TF_VAR_${lower_var_name}` という名前の環境変数に Secret 値をセットする

のステップを繰り返したのち、 `terraform` CLI を実行するようにしています。

## Terraform Variable の一覧について

Terraform の実行に必要な variable については、[`main.tf`](./main.tf)を参照してください。
