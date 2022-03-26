# proxy-kubernetes

seichi.click network 向けの Linode Kubernetes Engine(LKE) のクラスタ定義を管理するディレクトリです。

Production環境のBungeeCordは毎月10日20日30日の毎朝4時30分に、本リポジトリのGithub Actionsによって再起動されています。

概要図は `*/diagrams` 以下で、 draw.io によってパース可能なsvgファイルとして管理されています。これらを編集する場合は [Draw.io VS Code Integration](https://github.com/hediet/vscode-drawio) の利用を推奨します。

# 全体俯瞰図
![概要図](./diagrams/seichi-network-lke-infrastructure.drawio.svg)
| フルネーム  | 役割                                                                           | 
| ----------- | ------------------------------------------------------------------------------ | 
|  BungeeCord | Minecraftプロトコル用プロキシ                                                  | 
| cloudflared | Cloudflare Argo Tunnelを利用したオンプレ(うんちゃまクラウド)環境との接続に使用 | 

# 注意事項(主にレビュアーや運営チームな方向け)
本リポジトリはPublicリポジトリを想定し、seichi.click networkに関する公開可能なインフラ構成についての情報を取り扱っています。コントリビュート/レビューにあたっては以下の点に留意してください。
- 外部公開不可な情報(tokenやsecretなど)を復号可能な状態(平文やBASE64エンコしただけなど)でコードに含めないでください。Secretを追加する必要がある場合は、次のセクションを参照してください。
- 外部コントリビュータからpullreqを受けた場合は、workflowが承認待ち状態(※1)となります。pullreqに含まれるコードがworkflow等を通じて意図的に秘匿情報にアクセスしようとしていないか、必ずコードレビューをした上でworkflowのrunを承認するようお願いします。<br>
※1 Githubのリポジトリ設定で実現しています。具体的にはこちら：`Settings -> Actions -> General -> Fork pull request workflows from outside collaborators -> Require approval for all outside collaborators`

# `sealed-secrets` によるシークレット管理

本リポジトリでは [`sealed-secrets`](https://github.com/bitnami-labs/sealed-secrets)を用いることで、クラスタ上のアプリケーションの動作に必要なシークレットを秘匿しつつGit管理する方法を取っています。

アプリケーションの設定等でシークレットを追加する必要があるときは
 - <details>
     <summary>kubeseal CLI をローカル環境にインストール</summary>

      ```sh
      # kubesealのバージョン (https://github.com/bitnami-labs/sealed-secrets/releases を参照のこと)
      KUBESEAL_VERSION=0.17.3
      KUBESEAL_PLATFORM=linux-arm64

      KUBESEAL_ARCHIVE_FILENAME=kubeseal-${KUBESEAL_VERSION}-${KUBESEAL_PLATFORM}.tar.gz

      cd "$(mktemp -d)"
      wget "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/${KUBESEAL_ARCHIVE_FILENAME}"
      tar -xzvf "${KUBESEAL_ARCHIVE_FILENAME}"
      sudo mv kubeseal /usr/local/bin
      ```
    </details>

 - [クラスタ上に置いてある暗号化用の鍵ペアの公開鍵](https://sealed-secrets.bungee-proxy-public.seichi.click/v1/cert.pem)でシークレットを暗号化

   ```sh
   # --namespace には、このシークレットを読み取ることのできる範囲であるnamespaceの名前を入力
   kubeseal \
     --cert https://sealed-secrets.bungee-proxy-public.seichi.click/v1/cert.pem \
     --raw --from-file=/dev/stdin \
     --namespace <my-namespace> \
     --scope namespace-wide

   # 標準入力から暗号化が受け付けらるので、平文を入力し、Ctrl+Dで入力を終える
   ```

 - `SealedSecret` リソースを追加(例えば、 [./argocd-apps/argocd.yaml](./argocd-apps/argocd.yaml)の後半などに例があります)

するようにしてください。

# LKE クラスタのブートストラップについて

LKE 上で動いている(ArgoCD 以外の)すべての追加リソースはPull型の同期を行う ArgoCD によって管理されており、[`apps`](./apps/) ディレクトリ以下の特定のパスに対して行われた変更は ArgoCD によって自動的にクラスタに反映されます。

クラスタのブートストラップ、つまり ArgoCD 自体の管理は [Terraform](../terraform/) + [Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs) により行われています。そのため、クラスタを新規に作成した時は、LKE にアクセスするための認証情報を Terraform Cloud のシークレットに登録し、Plan + Apply を行うことで ArgoCD とルートプロジェクトを初期化してください。

Terraform Cloud に登録すべき認証情報等のより詳細な情報は [`main.tf`](../terraform/main.tf) の variable 定義を参照してください。
