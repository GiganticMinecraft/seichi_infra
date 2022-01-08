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

# 注意事項(主にレビュアーや運営チームな方向け)
本リポジトリはPublicリポジトリを想定し、seichi.click networkに関する公開可能なインフラ構成についての情報を取り扱っています。コントリビュート/レビューにあたっては以下の点に留意してください。
- 外部公開不可な情報(tokenやsecretなど)を復号可能な状態(平文やBASE64エンコしただけなど)でコードに含めないでください。
- 外部コントリビュータからpullreqを受けた場合は、workflowが承認待ち状態(※1)となります。pullreqに含まれるコードがworkflow等を通じて意図的に秘匿情報にアクセスしようとしていないか、必ずコードレビューをした上でworkflowのrunを承認するようお願いします。<br>
※1 Githubのリポジトリ設定で実現しています。具体的にはこちら：`Settings -> Actions -> General -> Fork pull request workflows from outside collaborators -> Require approval for all outside collaborators`

# 構築上の注意点

Kubernetesマニフェストの管理でArgoCDを利用する都合上、クラスターを1から再構築する際にはまず以下のコマンドにてArgoCDのインストールを実施してください。

```bash
helm upgrade --install argocd -n argocd argo/argo-cd --create-namespace
```
