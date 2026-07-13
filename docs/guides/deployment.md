# 開発者向けデプロイガイド

## 概要

整地鯖が提供するサーバー群への開発者向けデプロイ情報。

詳細は [DEPLOYMENT.md](https://github.com/GiganticMinecraft/seichi_infra/blob/main/DEPLOYMENT.md) を参照。

## インフラ概要

- 9台のベアメタルマシン（Proxmox）
- 約208コアvCPU、約960GBメモリ
- ネットワークストレージ: TrueNAS 3台 + Synology NAS 2台（iSCSI/NFS、合計20TiB超）、バックアップ用にProxmox Backup Server

## デプロイ方法の選択肢

### 1. 外部サービス（Cloudflare Pages等）

フロントエンドアプリケーションに最適。

### 2. Kubernetes上にデプロイ（推奨）

- Argo CDによるGitOpsデプロイ
- マニフェストをGitに配置するだけで自動デプロイ

### 3. VM上にデプロイ

旧来方式。Minecraftサーバー群は現在Kubernetes上（`seichi-minecraft` namespace）で稼働しており、VMが残っているのはProxmox Backup Server、NetBox、Redmineなど一部インフラ用途のみ。

## The Twelve-Factor App

- ステートを変数スコープで終わらせない
- 構成設定は環境変数で管理
- Graceful Shutdownに対応した設計
