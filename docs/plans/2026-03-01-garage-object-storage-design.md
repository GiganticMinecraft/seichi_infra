# Garage Object Storage 導入設計

## 概要

MinIO (2026年2月アーカイブ済み) の後継として Garage を導入し、
クラスタ内の全 S3 互換ストレージを統合する。
Thanos によるPrometheus長期メトリクス保存も同時に実現する。

## 全体アーキテクチャ

```
TrueNAS (HDD 10TB×5 RAIDZ1 ≈36TiB)     Synology (SSD 1.8TB×6 RAID5 ≈8.2TiB)
└── sc-truenas-03-iscsi                   └── synology-iscsi-storage
    └── Garage data PVC (4Ti × 3)             └── Garage metadata PVC (10Gi × 3)

Garage Cluster (garage namespace)
├── StatefulSet × 3 replicas (Worker node 各1台)
├── replication_factor: 2 (実効容量 ≈6Ti)
├── S3 API: ClusterIP :3900
├── RPC: Headless :3901
└── Admin/Metrics: ClusterIP :3903

Buckets:
├── thanos/              ← Prometheus 長期メトリクス
├── loki/                ← Loki ログチャンク+インデックス
├── mariadb-backups/     ← MariaDB 日次バックアップ
├── seichi-plugins/      ← プラグイン JAR + ワールドデータ
├── seichiassist/        ← SeichiAssist リリースアーティファクト
├── mc-worlds/           ← ワールドデータアップロード
└── tempo/               ← (将来) Tempo トレースデータ
```

## Phase 1: Garage デプロイ (本ドキュメントの実装対象)

### コンポーネント

1. **Terraform**: `garage` namespace 作成
2. **ArgoCD Application**: Garage Helm chart (Git リポジトリ参照)
3. **Helm values**: StatefulSet 3 replicas, SSD/HDD 分離ストレージ
4. **ServiceMonitor**: Prometheus メトリクス収集

### Garage Helm Chart

- Source: `https://github.com/deuxfleurs-org/garage` (branch: `main-v2`)
- Path: `script/helm/garage`
- Chart version: 0.9.2, appVersion: v2.2.0

### StatefulSet 構成

| 項目 | 値 |
|---|---|
| replicas | 3 |
| image | dxflrs/amd64_garage:v2.2.0 |
| replicationFactor | 2 |
| consistencyMode | consistent |
| dbEngine | lmdb |
| blockSize | 1048576 (1MiB) |
| compressionLevel | 1 (zstd) |

### ストレージ

| PVC | StorageClass | サイズ | 用途 |
|---|---|---|---|
| meta | synology-iscsi-storage (SSD) | 10Gi | メタデータ/インデックス (LMDB) |
| data | sc-truenas-03-iscsi (HDD) | 4Ti | オブジェクトデータ |

### ネットワーク

| Service | Type | Port | 用途 |
|---|---|---|---|
| garage | ClusterIP | 3900 | S3 API |
| garage-headless | Headless | 3901 | RPC (ノード間) |
| garage (admin) | ClusterIP | 3903 | Admin API + Metrics |

### リソース

```yaml
resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 2Gi
```

## Phase 2〜4: 移行 (別途計画)

- Phase 2: Loki を Garage に切り替え (MinIO subchart 無効化)
- Phase 3: Thanos 追加 (kube-prometheus-stack thanos sidecar 有効化)
- Phase 4: minio namespace の MinIO を Garage に移行 (16ファイル変更)

## MinIO 参照箇所 (移行対象、全16ファイル)

- terraform/onp_cluster_secrets.tf (3 Secret)
- terraform/onp_cluster_minecraft_secrets.tf (1 ClusterSecret)
- apps/cluster-wide-apps/app-of-other-apps/minio.yaml
- apps/cluster-wide-apps/app-of-other-apps/loki.yaml (MinIO subchart)
- apps/seichi-minecraft/mcserver--{s1,s2,s3,s5,s7,kagawa,votelistener,lobby,one-day-to-reset}/stateful-set.yaml (9ファイル)
- apps/seichi-minecraft/mariadb/argo-workflows-backup-all-databases.yaml
- apps/seichi-minecraft/mariadb/argo-workflows-restore.yaml
- apps/seichi-debug-minecraft/mariadb/mariadb.yaml
- apps/seichi-debug-minecraft/upload-world-to-minio/workflow-template.yaml
- apps/seichi-minecraft/seichiassist-downloader/sensor.yaml
- apps/cluster-wide-apps/minio-backup-to-pbs/ (backup/restore)
- app-templates/seichi-debug-minecraft-on-seichiassist-pr/templates/ (2ファイル)
- docker-images/mod-downloader/ (main.go, Dockerfile)
