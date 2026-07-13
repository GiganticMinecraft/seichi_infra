# Terraform運用ガイド

## 概要

Terraformで管理しているインフラの運用ガイド。

詳細は [terraform/README.md](https://github.com/GiganticMinecraft/seichi_infra/blob/main/terraform/README.md) を参照。

## 管理リソース

- **GitHub**: Teams、Repository設定
- **Cloudflare**: Access、証明書、DNS、Page rules、Pages
- **オンプレk8s**: Secret、Namespace、ArgoCD本体（helm_releaseによるブートストラップ）

## 実行環境

- 実行: GitHub Actions
- State管理: Terraform Cloud

## Cloudflare Tunnel経由のAPI接続

オンプレk8sへの接続はCloudflare Tunnel経由。

- `k8s-api.onp-k8s.admin.local-tunnels.seichi.click` → `127.0.0.1`
- cloudflaredでトンネルを作成してAPI接続

## Variable追加時の注意

Terraform variableは**すべて小文字のスネークケース**で定義すること。
対応するGitHub Actions Secretは `TF_VAR_` + 大文字スネークケース（例: `TF_VAR_CLOUDFLARE_API_KEY`）で登録する。
`expose-all-tf-vars-to-github-env.sh` がSecret名の `TF_VAR_` 以降を小文字に変換して環境変数として注入するため、この対応関係を崩さないこと。

## 関連リンク

- [Terraform Cloud](https://app.terraform.io/)
- [GitHub Actions Workflow](https://github.com/GiganticMinecraft/seichi_infra/actions)
