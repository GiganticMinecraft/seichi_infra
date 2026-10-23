# Trivy Operator 運用ガイド

## 概要

[Trivy Operator](https://aquasecurity.github.io/trivy-operator/) は、クラスタ内で実際に動いているワークロードを継続的にスキャンし、結果を Kubernetes のカスタムリソース (レポート) と Prometheus メトリクスとして公開する operator。

内製イメージは CI の `aquasecurity/trivy-action` でビルド時にスキャンし (ignore-unfixed、結果は GitHub Security タブ)、cosign 署名と BuildKit の SBOM attestation も付けている。Trivy Operator はこれを置き換えるものではなく、次を補う。

- **サードパーティイメージ**: Helm チャート由来のミドルウェアなど、CI を通らない約 100 イメージの脆弱性
- **継続的な再スキャン**: 稼働中のイメージを最新の脆弱性 DB で定期的にスキャンし直すので、ビルド後に公開された CVE にも気付ける
- **イメージ以外の検査**: ワークロード設定の監査 (ConfigAudit)、RBAC の評価、ノードの CIS 項目 (Infra Assessment)、CIS / NSA / PSS のコンプライアンスレポート

マニフェストは次の 2 か所。

- Application: `seichi-onp-k8s/manifests/seichi-kubernetes/apps/cluster-wide-apps/app-of-other-apps/trivy-operator.yaml`
- アラート: `seichi-onp-k8s/manifests/seichi-kubernetes/apps/cluster-wide-apps/trivy-operator-alerts/prometheusrule.yaml`

## 構成

すべて `trivy-operator` namespace に作られる。DaemonSet は無い。

| コンポーネント | 種類 | 役割 |
|---|---|---|
| `trivy-operator` | Deployment (1 replica) | ワークロードを監視し、スキャンジョブの作成とレポートの書き込みを行う。メトリクスも公開する |
| `trivy-server` | StatefulSet + PVC (5Gi) | 脆弱性 DB (~135MB) を 1 回だけ取得して保持し、スキャンジョブに配信する (`builtInTrivyServer: true`、ClientServer モード) |
| `scan-vulnerabilityreport-*` | Job | イメージ 1 つ (Pod 内のコンテナ全部) をスキャンする使い捨てジョブ。同時実行は `scanJobsConcurrentLimit` 本まで |
| `node-collector-*` | Job | ノードごとに 1 回起動し、kubelet / kube-apiserver / etcd などの設定ファイルを読んで CIS 項目を集める。control-plane にも toleration で配置する |

スキャン対象は全 namespace から `excludeNamespaces` に一致するもの (SeichiAssist の PR ごとの使い捨て環境 `seichi-debug-minecraft-on-seichiassist-pr-*`) を除いたもの。イメージはすべて公開イメージなので imagePullSecret の設定は無い。

レポートは operator が作るカスタムリソースで、Argo CD の管理対象ではない。

## レポートの見方

脆弱性レポート (イメージ単位、MEDIUM 以上・修正版ありのみ):

```bash
# 全 namespace の一覧 (CRITICAL / HIGH / MEDIUM の件数が列に出る)
kubectl get vulnerabilityreports -A -o wide

# 特定のレポートの CVE 一覧
kubectl get vulnerabilityreports -n seichi-minecraft <name> \
  -o jsonpath='{range .report.vulnerabilities[*]}{.severity}{"\t"}{.vulnerabilityID}{"\t"}{.resource}{"\t"}{.installedVersion}{" -> "}{.fixedVersion}{"\n"}{end}'
```

レポート名は `<ワークロード種別>-<ワークロード名>-<コンテナ名>` (例: `daemonset-k8s-monitoring-alloy-logs-alloy`)。元のワークロードはラベル `trivy-operator.resource.kind` / `trivy-operator.resource.name` で引ける。

その他のレポート:

```bash
# ワークロード設定の監査 (privileged、resources 未設定など)
kubectl get configauditreports -A

# CIS / NSA / PSS のコンプライアンス集計
kubectl get clustercompliancereports -o wide

# ノードの CIS 項目
kubectl get clusterinfraassessmentreports

# RBAC の評価
kubectl get rbacassessmentreports -A
kubectl get clusterrbacassessmentreports
```

## Grafana ダッシュボード

Grafana の **Kubernetes** フォルダにある「**Trivy Operator - Vulnerabilities**」(uid `security_trivy_operator`) を使う。`grafana-dashboards-kubernetes` Application が配布しているもので、`trivy_image_vulnerabilities` (イメージ × 重大度の件数) と `trivy_vulnerability_id` (CVE ID 単位、`metricsVulnIdEnabled: true` で出力) を表示する。

脆弱性の対応 (どのイメージを上げるか、どの CVE を無視するか) はこのダッシュボードを見て判断する。脆弱性の件数ではアラートを出さない。MEDIUM 以上の脆弱性はサードパーティイメージのどこかに常に存在するので、件数アラートは鳴りっぱなしで Discord に 4 時間ごとに再通知されるだけになるため。

## アラート

`trivy-operator-alerts` の 3 つはいずれも `severity: warning` / `notify: discord`。スキャン基盤そのものの故障だけを通知する。

| アラート | 条件 | 対応 |
|---|---|---|
| `TrivyOperatorDown` | operator が 15 分以上 scrape できない | `kubectl -n trivy-operator get pods` で CrashLoopBackOff / OOMKilled / Pending を確認。OOMKilled なら Application の `resources.limits.memory` を上げる |
| `TrivyScanJobsFailing` | 直近 1 時間に失敗したスキャンジョブが 4 件以上の状態が 30 分続く | `kubectl -n trivy-operator logs deploy/trivy-operator` で失敗理由を確認。DB 取得失敗 (mirror.gcr.io への到達性)、イメージ pull 失敗、Kyverno の webhook 停止、OOMKilled、タイムアウトが典型 |
| `TrivyVulnerabilityReportsMissing` | operator は up なのに `trivy_image_vulnerabilities` が 2 時間以上無い | スキャンが 1 件も成功していない。`kubectl -n trivy-operator get jobs`、operator と `trivy-server` のログを確認 |

## チューニング

値はすべて Application の `helm.values` 内、`---- チューニング値 ----` で囲んだブロックにある。

- **再スキャン周期**: `operator.scannerReportTTL` (現在 72h)。レポートが期限切れになると再スキャンされる。短くすると新しい CVE に早く気付けるが、Java イメージごとに ~1GB の Java DB 取得が走る
- **同時実行数**: `operator.scanJobsConcurrentLimit` (現在 2)。上げるとスキャンが早く終わるが、1 ジョブ最大 2Gi のメモリを並列分確保する。wk-2 / wk-3 のメモリ requests が逼迫している点に注意
- **タイムアウト**: `operator.scanJobTimeout` と `trivy.timeout` (どちらも 15 分) を揃えて変える
- **`operator.scanJobTTL` は設定しない**: 未設定なら終わった Job は operator が即時削除する。設定すると削除が `ttlSecondsAfterFinished` 任せになる一方、同時実行数の判定は namespace 内の Job を状態に関係なく数えるので、完了済み Job が TTL の間ずっと同時実行枠を占有してスキャンが止まる
- **重大度**: `trivy.severity` (現在 `MEDIUM,HIGH,CRITICAL`)。LOW を含めるとレポートと `trivy_vulnerability_id` のカーディナリティが大きく増える
- **namespace を除外する**: `excludeNamespaces` にカンマ区切りで追加する (glob 可)
- **イメージを除外する**: `trivyOperator.excludeImages` にカンマ区切りの glob を書く (例: `docker.io/library/busybox:*`)
- **特定のワークロードを除外する**: `trivyOperator.skipResourceByLabels` にラベルキーを書き、対象ワークロードにそのラベルを付ける
- **CVE を無視する**: `trivy.ignoreFile` に `.trivyignore` の内容を書く

```yaml
trivy:
  ignoreFile:
    - CVE-2026-12345  # 理由と見直し期限をコメントで残す
```

## 既知の制約

- **Java DB はスキャンジョブごとに取得される**: trivy-server が配信するのは本体の脆弱性 DB だけで、JAR を含むイメージをスキャンするたびにジョブ側で Java index DB (~1GB 圧縮) をダウンロードする。Minecraft 系の Java イメージが約 45 個あるので、再スキャン周期を短くするとそのぶん通信量が増える
- **scanJobTTL と同時実行枠**: 上記の通り `operator.scanJobTTL` を設定すると完了 Job が同時実行枠を占有し、スキャンが TTL の間止まる (実証実験で limit 2 / TTL 10m にして 10 分停止を再現)
- **Kyverno の webhook に依存する**: Kyverno の webhook は failurePolicy=Fail なので、Kyverno が落ちている間はスキャンジョブを作れない (`TrivyScanJobsFailing` / `TrivyVulnerabilityReportsMissing` の原因になり得る)
- **node-collector は root で動く**: hostPID と root、`/etc/kubernetes` などの read-only hostPath マウントが必要。`trivyOperator.scanJobPodTemplatePodSecurityContext` を設定すると node-collector にも適用されて動かなくなるので、空のままにする。PSA でこの namespace を restricted / baseline にすることもできない
- **レポートは Argo CD で追跡されない**: operator が作るリソースなので、Argo CD の画面には出ない。kubectl かダッシュボードで見る
- **ReplicaSet が変わるたびに再スキャンされる**: レポートは ReplicaSet 単位なので、Deployment の rollout (イメージ更新に限らず annotation の変更でも) のたびに新しい ReplicaSet がスキャンされる。Renovate の digest 更新が多い日はスキャンジョブも増える

## 実証実験

<!-- PoC 実測値: 親セッションで追記 -->

## 経緯

- 2025-03〜2025-09 に Argo CD Application `trivy-operator` (chart 0.30.0) として導入されていたが、PR #3633 で理由の記載なく削除された
- 削除後もクラスタスコープのリソースが残っていた: CRD 6 種、`argocd.argoproj.io/instance=trivy-operator` ラベル付きの ClusterRole / ClusterRoleBinding `trivy-operator`、owner の無い ClusterComplianceReport 4 件、ClusterRbacAssessmentReport 約 218 件
- 2026-10 に chart 0.37.0 で再導入した。Application 名と releaseName を当時と同じ `trivy-operator` にしたので、残っていた CRD と ClusterRole / ClusterRoleBinding はそのまま Argo CD の管理下に戻る (CRD のスキーマは 0.37.0 と同一)
