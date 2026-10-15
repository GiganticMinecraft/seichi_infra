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
さらに `.github/workflows/terraform_pr.yaml` と `terraform_apply.yaml` の `env:` に `TF_VAR_<小文字名>: ${{ secrets.TF_VAR_<大文字名> }}` の行を両方とも追加すること（Secretは自動では渡されない）。

## 関連リンク

- [Terraform Cloud](https://app.terraform.io/)
- [GitHub Actions Workflow](https://github.com/GiganticMinecraft/seichi_infra/actions)
