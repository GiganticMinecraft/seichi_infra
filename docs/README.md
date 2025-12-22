# seichi_infra ドキュメント

整地鯖インフラの運用ドキュメント。

Wiki.jsと同期して https://wiki.onp-k8s.admin.seichi.click で閲覧可能。

## Runbooks（運用手順書）

定例作業や障害対応の手順書。

- [Proxmoxバージョンアップ](./runbooks/proxmox-upgrade.md)
- [Kubernetesクラスターバージョンアップ](./runbooks/k8s-cluster-upgrade.md)
- [Kubernetes証明書更新](./runbooks/k8s-cert-renewal.md)
- [Cloudflare証明書更新](./runbooks/cloudflare-cert-renewal.md)
- [Minecraftメンテナンスモード](./runbooks/maintenance-mode.md)

## Guides（ガイド）

開発者・運用者向けのガイド。

- [開発者向けデプロイガイド](./guides/deployment.md)
- [Kubernetesクラスタ構築](./guides/cluster-setup.md)
- [Terraform運用](./guides/terraform.md)

## 編集方法

1. このリポジトリの`docs/`ディレクトリを編集
2. PRを作成してレビュー
3. mainにマージ後、Wiki.jsに自動同期
