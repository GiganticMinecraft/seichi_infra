# `seichi_infra`

seichi.click networkのオンプレ環境のうち、公開可能な箇所を管理するレポジトリです。

概要図は `*/diagrams` 以下で、 draw.io によってパース可能なsvgファイルとして管理されています。これらを編集する場合は [Draw.io VS Code Integration](https://github.com/hediet/vscode-drawio) の利用を推奨します。

## [Terraform](./terraform) 管理下にあるもの

 - Cloudflare周りの設定
 - GitHub Teamsの定義
 - Cloudflare周りの設定
   - 証明書の管理
   - GitHub Teamsを用いたアクセス制御の定義
 - LKE上の一部オブジェクトの管理
   - Cloudflareが発行したトークンを含むSecretリソース

## サーバー一覧

 - [seichi-authenticator](./seichi-authenticator/README.md)(SSO等の認証用サーバー)
