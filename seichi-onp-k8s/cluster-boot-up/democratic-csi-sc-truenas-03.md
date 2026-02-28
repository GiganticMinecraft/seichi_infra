# democratic-csi (sc-truenas-03) のセットアップ

このドキュメントは、TrueNAS Scale ストレージ `sc-truenas-03` (192.168.16.234) を
iSCSI バックエンドとして使用する CSI ドライバー `democratic-csi` を
クラスタで動作させるために必要な設定手順を記述しています。

## 概要

`democratic-csi` の認証情報は Terraform 経由で Kubernetes Secret として注入されます。
Terraform 変数の実体は **GitHub Actions の Repository Secret** として管理されており、
`TF_VAR_` プレフィックスを持つ Secret は CI が自動で Terraform 変数として渡します。

```
GitHub Actions Secret
  TF_VAR_ONP_K8S_DEMOCRATIC_CSI_SC_TRUENAS_03_DRIVER_CONFIG
        ↓ .github/workflows/scripts/expose-all-tf-vars-to-github-env.sh が変換
Terraform variable
  onp_k8s_democratic_csi_sc_truenas_03_driver_config
        ↓ terraform/onp_cluster_secrets.tf が apply
Kubernetes Secret
  democratic-csi/democratic-csi-driver-config-sc-truenas-03
        ↓ ArgoCD が参照
democratic-csi CSI ドライバー
```

## 前提: sc-truenas-03 側の設定

GitHub Secret を作成する前に、TrueNAS Scale WebUI で以下が設定済みであること。

| 項目 | 設定値 |
|------|--------|
| iSCSI サービス | 有効化済み |
| iSCSI ポータル IP | 192.168.16.234:3260 |
| iSCSI ポータル Group ID | 1 |
| iSCSI Initiator Group | 全許可、Group ID: 1 |
| ZFS データセット (volumes) | `pool-01/dataset-seichi-onp-k8s-01/volumes` |
| ZFS データセット (snapshots) | `pool-01/dataset-seichi-onp-k8s-01/snapshots` |

## セットアップ手順

### 1. TrueNAS Scale で API Key を発行する

TrueNAS Scale WebUI > **Credentials > API Keys** から新しい API Key を作成し、値を控えておく。

### 2. GitHub Actions Repository Secret を登録する

https://github.com/GiganticMinecraft/seichi_infra/settings/secrets/actions にアクセスし、
**Repository secrets** に以下の Secret を追加する。

**Secret 名:**
```
TF_VAR_ONP_K8S_DEMOCRATIC_CSI_SC_TRUENAS_03_DRIVER_CONFIG
```

**Secret の値:** 下記 YAML の `<TRUENAS_API_KEY>` を手順 1 で取得した値に置き換えたもの。

```yaml
driver: freenas-scale-api-iscsi
httpConnection:
  protocol: https
  host: 192.168.16.234
  port: 443
  allowInsecure: true
  apiKey: <TRUENAS_API_KEY>
zfs:
  datasetParentName: pool-01/dataset-seichi-onp-k8s-01/volumes
  detachedSnapshotsDatasetParentName: pool-01/dataset-seichi-onp-k8s-01/snapshots
  datasetEnableQuotas: true
  datasetEnableReservation: false
iscsi:
  targetPortal: 192.168.16.234:3260
  namePrefix: csi-
  nameSuffix: "-seichi-onp-k8s"
  targetGroups:
    - targetGroupPortalGroup: 1
      targetGroupInitiatorGroup: 1
      targetGroupAuthType: None
  extentInsecureTpc: true
  extentDisablePhysicalBlocksize: true
  extentBlocksize: 512
  extentRpm: SSD
```

### 3. Secret が反映されたことを確認する

Secret 登録後、main ブランチへのマージをトリガーに `terraform apply` が自動実行され、
`democratic-csi` namespace に `democratic-csi-driver-config-sc-truenas-03` Secret が作成される。

以下のコマンドで確認する。

```bash
ssh seichi-onp-k8s-cp-1 "kubectl get secret democratic-csi-driver-config-sc-truenas-03 -n democratic-csi"
```

Secret が作成されると ArgoCD が `democratic-csi-sc-truenas-03` Application を自動デプロイし、
`sc-truenas-03-iscsi` StorageClass が利用可能になる。

## API Key のローテーション

1. TrueNAS Scale WebUI で新しい API Key を発行する
2. GitHub Actions Repository Secret `TF_VAR_ONP_K8S_DEMOCRATIC_CSI_SC_TRUENAS_03_DRIVER_CONFIG` を新しい値で更新する
3. GitHub Actions で `terraform apply` を手動実行する (`workflow_dispatch`)
4. CSI コントローラーを再起動する

```bash
ssh seichi-onp-k8s-cp-1 "kubectl rollout restart deployment -n democratic-csi"
```
