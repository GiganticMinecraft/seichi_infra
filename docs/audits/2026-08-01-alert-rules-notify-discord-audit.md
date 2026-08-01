# アラートルール監査と notify=discord 段階付与の方針 (2026-08-01)

対象 issue: [#5602](https://github.com/GiganticMinecraft/seichi_infra/issues/5602)

## 背景

Alertmanager の Discord 通知経路 (#5601) は `notify=discord` ラベルによる明示 opt-in
方式を採る。既存アラートルールを監査し、通知価値のあるものから段階的にラベルを
付与する。

## インベントリ (2026-08-01 時点)

Prometheus (`/api/v1/rules`) の実測。#5599/#5628 で Alertmanager の defaultRules
(9 本) が有効化されたため、issue 作成時の 175 本から増えている。

| severity | 本数 | 主な出所 |
| --- | --- | --- |
| critical | 40 | kube-prometheus-stack defaultRules |
| warning | 104 | kube-prometheus-stack defaultRules |
| error (独自) | 30 | Valkey/Redis チャート values (27) + thanos (3) |
| info | 7 | kube-prometheus-stack defaultRules |
| none | 2 | Watchdog / InfoInhibitor (意図的) |
| 未設定 | 1 | KedaScalerErrors (KEDA チャート付属) |
| **合計** | **184** | |

## 付与の仕組み

ルールの大半は kube-prometheus-stack がチャート内で生成する defaultRules であり、
個別ルールの定義にラベルを足すには「該当ルールを disable して
additionalPrometheusRulesMap に再定義」する必要があり、チャート更新への追従性が
悪い。そのため **Prometheus の alert relabeling
(`prometheusSpec.additionalAlertRelabelConfigs`) で Alertmanager への送信時に
`notify=discord` を付与する** 方式を採る。

- 付与対象は `alertname;severity` の列挙で管理する (prometheus-operator.yaml)
- `ALERTS` メトリクスには影響しない → **kured の alertFilterRegexp の挙動を変えない**
- Loki ruler のアラートには適用されない → Loki 側はルール定義に直接
  `notify: discord` を書く (loki-alert-rules/)
- 自前の PrometheusRule (seichi-portal-alerts 等) もルール定義に直接書く

## critical 40 本の監査

判定基準: 「firing したら (営業時間外でも) 人間が見て意味があるか」「誤発火・
常時発火の実績がないか」。

### 第 1 弾: 即付与 (12 本)

クラスタ・データの生死に直結し、自動回復が期待できないもの。

| alertname | 理由 |
| --- | --- |
| etcdInsufficientMembers | quorum 喪失間近。放置するとクラスタ全停止 |
| etcdNoLeader | 同上 |
| KubeAPIDown | コントロールプレーン停止 |
| KubeControllerManagerDown | 同上 |
| KubeSchedulerDown | 同上 |
| KubeletDown | ノード上の kubelet 全滅系。medik8s の自動修復対象外のケースあり |
| NodeRAIDDegraded | ディスク冗長性喪失。もう 1 本壊れるとデータロス |
| KubePersistentVolumeErrors | PV プロビジョニング失敗。ワークロード起動不能 |
| KubePersistentVolumeFillingUp (critical) | 残 3% 未満。溢れるとアプリ停止 |
| NodeFilesystemAlmostOutOfSpace (critical) | ノードディスク残 3% 未満。kubelet eviction が始まる |
| AlertmanagerClusterDown | 通知経路自体の停止 (自己監視) |
| PrometheusErrorSendingAlertsToAnyAlertmanager | 同上。これが firing している間は他の通知が届かない |

### 保留: 次バッチ候補 (ノイズ観察後に判断)

- KubeAPIErrorBudgetBurn (2): SLO バーンレート。閾値が本クラスタの規模に
  合っているか観察が必要
- KubeClientCertificateExpiration / KubeletClientCertificateExpiration /
  KubeletServerCertificateExpiration (critical, 3): 残 24h。kubeadm 環境では
  kubelet 証明書は自動ローテーションのため、firing 実績を見てから
- NodeFilesystemSpaceFillingUp / FilesFillingUp / AlmostOutOfFiles (critical, 3):
  予測系・inode 系。AlmostOutOfSpace で実害はカバーされる
- NodeFileDescriptorLimit (critical): 実績観察待ち
- KubePersistentVolumeInodesFillingUp (critical): inode 系
- etcdHighNumberOfFailedGRPCRequests / etcdGRPCRequestsSlow /
  etcdHighFsyncDurations (critical, 3) / etcdDatabaseQuotaLowSpace: 性能劣化系。
  kured の再起動窓や NAS の負荷で誤発火しないか観察してから
- Prometheus 系の残り (PrometheusBadConfig / PrometheusRuleFailures /
  PrometheusRemoteStorageFailures / PrometheusRemoteWriteBehind /
  PrometheusTargetSyncFailure, 5): GitOps 経由の設定ミスは kubechecks と
  ArgoCD sync 状態でも検知できるため優先度を下げる
- AlertmanagerFailedReload / AlertmanagerMembersInconsistent /
  AlertmanagerConfigInconsistent / AlertmanagerClusterCrashlooping /
  AlertmanagerClusterFailedToSendAlerts (critical, 5): 自己監視系の残り。
  ClusterDown と ErrorSendingAlertsToAnyAlertmanager でまず様子を見る
- KubeStateMetricsListErrors / WatchErrors / ShardingMismatch / ShardsMissing (4):
  メトリクス収集系。多数の他アラートの誤発火という形でも顕在化するため保留

## severity 統一方針

独自 severity `error` (30 本) を廃止し、kube-prometheus-stack 標準の
critical / warning / info の 3 値に統一する。

**統一する動機**: chart 既定の Alertmanager inhibit_rules は
critical → warning|info の抑制関係しか知らないため、`error` は抑制グラフに
参加できない。また kured の除外判断や監査のたびに独自値の解釈が必要になる。

**振り分け基準**:

| 現 error ルール | 新 severity | 理由 |
| --- | --- | --- |
| 本番 ns (seichi-minecraft / seichi-gateway) の ValkeyDown/RedisDown | critical | セッション/セマフォ喪失は MC サーバー影響が直撃 |
| 本番 ns の ValkeyMemoryHigh / ValkeyKeyEviction | warning | 劣化の予兆であり即断は不要 |
| seichi-debug-* ns の Valkey/Redis 系 (12 本) | info | debug 環境。通知対象外 |
| thanos 3 本 (UploadStale / UploadFailures / OperationFailures) | warning | 長期保存の欠損リスクだが即時対応は不要 (30d retention 内に直せばよい) |

**実装箇所** (別 PR で実施):

- Valkey/Redis ルール: `apps/seichi-minecraft/valkey/*.yaml`、
  `apps/seichi-debug-gateway/bungeecord/*.yaml` の Application values 内
  `metrics.prometheusRule.rules[].labels.severity`
- thanos ルール: `app-of-other-apps/prometheus-operator.yaml` の
  additionalPrometheusRulesMap
- KedaScalerErrors (未設定): KEDA チャート側の定義。values で上書き可能か確認する

## 運用

- 第 1 弾適用後、通知の頻度・重複を観察し、route の group_by / group_interval /
  repeat_interval (現在 alertname+namespace+service / 5m / 4h) を調整する
- ノイズになったルールは列挙から外す (relabel の列挙が opt-in リストそのもの)
- 次バッチは月次程度で見直す
