# Terraform運用ガイド

## 概要

Terraformで管理しているインフラの運用ガイド。

詳細は [terraform/README.md](https://github.com/GiganticMinecraft/seichi_infra/blob/main/terraform/README.md) を参照。

## 管理リソース

- **GitHub**: Teams、Repository設定
- **Cloudflare**: Access、証明書、DNS、Page rules
- **オンプレk8s**: Secret、Namespace

## 実行環境

- 実行: GitHub Actions
- State管理: Terraform Cloud

## Cloudflare Tunnel経由のAPI接続

オンプレk8sへの接続はCloudflare Tunnel経由。

- `k8s-api.onp-k8s.admin.local-tunnels.seichi.click` → `127.0.0.1`
- cloudflaredでトンネルを作成してAPI接続

## Variable追加時の注意

GitHub Actions SecretからTerraform variableに変換する際、**すべて大文字のスネークケース**で定義すること。

## 関連リンク

- [Terraform Cloud](https://app.terraform.io/)
- [GitHub Actions Workflow](https://github.com/GiganticMinecraft/seichi_infra/actions)
