# `seichi_infra`

seichi.click networkのオンプレ環境のうち、公開可能な箇所を管理するレポジトリです。

概要図は [`diagrams`](./diagrams) 以下で、 draw.io によってパース可能なsvgファイルとして管理されています。これらを編集する場合は [Draw.io VS Code Integration](https://github.com/hediet/vscode-drawio) の利用を推奨します。

## ディレクトリ構成

 - [`diagrams`](./diagrams/)
   - 概要図、ネットワーク構成図などの図を draw.io で描いて管理するディレクトリ。
   - 2022/03/18現在、GitHubがmermaidのレンダリングを正式にサポートしたため、新しい図はmermaidで作成して良いかも
 
 - [`seichi-onp-k8s`](./seichi-onp-k8s/)
   - オンプレ環境の k8s クラスタの定義を管理するディレクトリ。詳細は [README](./seichi-onp-k8s/README.md) を参照してください。

 - [`terraform`](./terraform/)
   - [Terraform Cloud](https://app.terraform.io/app/GiganticMinecraft/workspaces/seichi_infra) に管理させているインフラ全般の設定です。
   - 2022/03/18現在、 Terraform Cloud 管理下にある設定および定義は以下の通りです
     - GitHub Teamsの定義
     - Cloudflare周りの設定
       - 証明書の管理
       - GitHub Teamsを用いたアクセス制御の定義
     - オンプレ環境の k8s クラスタ上の一部リソースの管理
       - 現時点では主に `Secret` リソースと `Namespace` リソースだけ Terraform で管理している

 - [`util-scripts`](./util-scripts/)
   - サーバーなどが利用できるように組まれた雑多なインストールスクリプト等を管理しています。

## ライセンスについて

本リポジトリで記述されている設定自体は[ライセンス](./LICENSE.md)の範囲内で利用していただけます。

ただし、BungeeCordのサービス定義は、[著作権で保護されている、まいんちゃんのサーバーアイコン](https://github.com/GiganticMinecraft/branding)をダウンロードして利用するように設定されています。当該設定を流用する場合は[`branding` レポジトリ](https://github.com/GiganticMinecraft/branding)の利用許諾に記載されている条件に従う必要があるため、以下のどちらかを満たすように設定してください：
 - BungeeCord の Deployment リソースでのサーバーアイコンのURL指定(`SERVER_ICON_URL` 環境変数)をまいんちゃんアイコン以外のものに差し替える
 - 不特定多数が BungeeCord に接続できないようにする
