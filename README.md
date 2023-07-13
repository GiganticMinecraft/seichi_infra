# `seichi_infra`

seichi.click networkのオンプレ環境のうち、公開可能な箇所を管理するレポジトリです。

概要図は [`diagrams`](./diagrams) 以下で、 draw.io によってパース可能なsvgファイルとして管理されています。これらを編集する場合は [Draw.io VS Code Integration](https://github.com/hediet/vscode-drawio) の利用を推奨します。

## 開発者向けデプロイガイド

[DEPLOYMENT.md](./DEPLOYMENT.md) を参照してください。

## ディレクトリ構成

 - [`diagrams`](./diagrams/)
   - 概要図、ネットワーク構成図などの図を draw.io で描いて管理するディレクトリ。
   - 2022/03/18現在、GitHubがmermaidのレンダリングを正式にサポートしたため、新しい図はmermaidで作成して良いかも
 
 - [`seichi-onp-k8s`](./seichi-onp-k8s/)
   - オンプレ環境の k8s クラスタの定義を管理するディレクトリ。詳細は [README](./seichi-onp-k8s/README.md) を参照してください。

 - [`terraform`](./terraform/)
   - Terraformを用いて一部のインフラを管理しており、それらの設定はすべてこのディレクトリで管理されています。詳細は [README](./terraform/README.md) を参照してください。

 - [`util-scripts`](./util-scripts/)
   - サーバーなどが利用できるように組まれた雑多なインストールスクリプト等を管理しています。

## ライセンスについて

本リポジトリで記述されている設定自体は[ライセンス](./LICENSE.md)の範囲内で利用していただけます。

ただし、BungeeCordのサービス定義は、[著作権で保護されている、まいんちゃんのサーバーアイコン](https://github.com/GiganticMinecraft/branding)をダウンロードして利用するように設定されています。当該設定を流用する場合は[`branding` レポジトリ](https://github.com/GiganticMinecraft/branding)の利用許諾に記載されている条件に従う必要があるため、以下のどちらかを満たすように設定してください：
 - BungeeCord の Deployment リソースでのサーバーアイコンのURL指定(`SERVER_ICON_URL` 環境変数)をまいんちゃんアイコン以外のものに差し替える
 - 不特定多数が BungeeCord に接続できないようにする
