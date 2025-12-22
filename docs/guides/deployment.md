# 開発者向けデプロイガイド

## 概要

整地鯖が提供するサーバー群への開発者向けデプロイ情報。

詳細は [DEPLOYMENT.md](https://github.com/GiganticMinecraft/seichi_infra/blob/main/DEPLOYMENT.md) を参照。

## インフラ概要

- 9台のベアメタルマシン（Proxmox）
- 約208コアvCPU、約960GBメモリ
- 7TB SSD（Synology NAS）

## デプロイ方法の選択肢

### 1. 外部サービス（Cloudflare Pages等）

フロントエンドアプリケーションに最適。

### 2. Kubernetes上にデプロイ（推奨）

- Argo CDによるGitOpsデプロイ
- マニフェストをGitに配置するだけで自動デプロイ

### 3. VM上にデプロイ

独自プラグインを含むMinecraftサーバー向け。

## The Twelve-Factor App

- ステートを変数スコープで終わらせない
- 構成設定は環境変数で管理
- Graceful Shutdownに対応した設計
