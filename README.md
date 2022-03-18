# `seichi_infra`

seichi.click networkのオンプレ環境のうち、公開可能な箇所を管理するレポジトリです。

概要図は [`diagrams`](./diagrams) 以下で、 draw.io によってパース可能なsvgファイルとして管理されています。これらを編集する場合は [Draw.io VS Code Integration](https://github.com/hediet/vscode-drawio) の利用を推奨します。

## ディレクトリ構成

 - [`diagrams`](./diagrams/)
   - 概要図、ネットワーク構成図などの図を draw.io で描いて管理するディレクトリ。
   - 2022/03/18現在、GitHubがmermaidのレンダリングを正式にサポートしたため、新しい図はmermaidで作成して良いかも

 - [`proxy-kubernetes`](./proxy-kubernetes/)
   - Linode Kubernetes Engine(LKE) 上の k8s クラスタの定義を管理するディレクトリ。詳細は [README](./proxy-kubernetes/README.md) を参照してください。
 
 - [`terraform`](./terraform/)
   - [Terraform Cloud](https://app.terraform.io/app/GiganticMinecraft/workspaces/seichi_infra) に管理させているインフラ全般の設定です。
   - 2022/03/18現在、 Terraform Cloud 管理下にある設定および定義は以下の通りです
     - GitHub Teamsの定義
     - Cloudflare周りの設定
       - 証明書の管理
       - GitHub Teamsを用いたアクセス制御の定義
     - LKE上の一部オブジェクトの管理
       - Cloudflareが発行したトークンを含むSecretリソース

 - [`util-scripts`](./util-scripts/)
   - サーバーなどが利用できるように組まれた雑多なインストールスクリプト等を管理しています。
