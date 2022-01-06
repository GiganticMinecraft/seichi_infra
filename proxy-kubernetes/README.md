# seichi_bungee

seichi.click network 向けの Linode Kubernetes Engine(LKE) のクラスタ定義を管理するレポジトリです。

Production環境のBungeeCordは毎月10日20日30日の毎朝4時30分に、本リポジトリのGithub Actionsによって再起動されています。

概要図は `*/diagrams` 以下で、 draw.io によってパース可能なsvgファイルとして管理されています。これらを編集する場合は [Draw.io VS Code Integration](https://github.com/hediet/vscode-drawio) の利用を推奨します。

# 全体俯瞰図
![概要図](./diagrams/seichi-network-lke-infrastructure.drawio.svg)
| フルネーム  | 役割                                                                           | 
| ----------- | ------------------------------------------------------------------------------ | 
|  BungeeCord | Minecraftプロトコル用プロキシ                                                  | 
| cloudflared | Cloudflare Argo Tunnelを利用したオンプレ(うんちゃまクラウド)環境との接続に使用 | 

# 外部公開禁止
本リポジトリはPrivateリポジトリを想定して作成されており、seichi.click networkインフラにまつわるいくつかの機密情報を含みます。本リポジトリの一部、全部を許可なく外部公開することを禁じます。

# 構築上の注意点

Kubernetesマニフェストの管理でArgoCDを利用する都合上、クラスターを1から再構築する際にはまず以下のコマンドにてArgoCDのインストールを実施してください。

```bash
helm upgrade --install argocd -n argocd argo/argo-cd --create-namespace
```
