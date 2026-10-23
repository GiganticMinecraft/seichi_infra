# Trivy Operator 運用ガイド

## 概要

[Trivy Operator](https://aquasecurity.github.io/trivy-operator/) は、クラスタ内で実際に動いているワークロードを継続的にスキャンし、結果を Kubernetes のカスタムリソース (レポート) と Prometheus メトリクスとして公開する operator。

内製イメージは CI の `aquasecurity/trivy-action` でビルド時にスキャンし (ignore-unfixed、結果は GitHub Security タブ)、cosign 署名と BuildKit の SBOM attestation も付けている。Trivy Operator はこれを置き換えるものではなく、次を補う。

- **サードパーティイメージ**: Helm チャート由来のミドルウェアなど、CI を通らない約 100 イメージの脆弱性
- **継続的な再スキャン**: 稼働中のイメージを最新の脆弱性 DB で定期的にスキャンし直すので、ビルド後に公開された CVE にも気付ける
- **イメージ以外の検査**: ワークロード設定の監査 (ConfigAudit)、RBAC の評価、ノードの CIS 項目 (Infra Assessment)、CIS / NSA / PSS のコンプライアンスレポート

マニフェストは次の 2 か所。

- Application: `seichi-onp-k8s/manifests/seichi-kubernetes/apps/cluster-wide-apps/app-of-other-apps/trivy-operator.yaml`
- アラート: `seichi-onp-k8s/manifests/seichi-kubernetes/apps/cluster-wide-apps/trivy-operator-alerts/prometheusrule.yaml` (Prometheus) と `cluster-wide-apps/loki-alert-rules/trivy-operator.yaml` (Loki)

## 構成

すべて `trivy-operator` namespace に作られる。DaemonSet は無い。

| コンポーネント | 種類 | 役割 |
|---|---|---|
| `trivy-operator` | Deployment (1 replica) | ワークロードを監視し、スキャンジョブの作成とレポートの書き込みを行う。メトリクスも公開する |
| `trivy-server` | StatefulSet + PVC (5Gi) | 脆弱性 DB (~135MB) を 1 回だけ取得して保持し、スキャンジョブに配信する (`builtInTrivyServer: true`、ClientServer モード) |
| `scan-vulnerabilityreport-*` | Job | イメージ 1 つ (Pod 内のコンテナ全部) をスキャンする使い捨てジョブ。同時実行は `scanJobsConcurrentLimit` 本まで |
| `node-collector-*` | Job | ノードごとに 1 回起動し、kubelet / kube-apiserver / etcd などの設定ファイルを読んで CIS 項目を集める。control-plane にも toleration で配置する |

スキャン対象は全 namespace から `excludeNamespaces` に一致するもの (SeichiAssist の PR ごとの使い捨て環境 `seichi-debug-minecraft-on-seichiassist-pr-*`) を除いたもの。イメージはすべて公開イメージなので imagePullSecret の設定は無い。Docker Hub の匿名 pull には egress IP 単位の制限がある (2026-10-23 にクラスタ内から `ratelimit-limit` ヘッダを取得したところ 100 回 / 3600 秒。Docker 側の方針変更で変わり得る) ので、同時実行数や再スキャン周期を大きく変えるときは意識すること。

完了済みの Job も対象 (mariadb-operator の Backup が作る Job など) だが、既に取得できないイメージを持つ古い Job が残っていると 30 秒ごとに pull しに行って失敗し続けるため、該当イメージを `trivyOperator.excludeImages` で完全一致で除外している (Application のコメントを参照)。

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

`kubectl get vulnerabilityreports -A -o wide` の UNKNOWN 列は多めに出る。これは「未評価」ではなく「Trivy は MEDIUM 以上と判定したがベンダー severity が無い」脆弱性で、理由は下の「既知の制約」を参照。

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

Grafana の **Trivy** フォルダにある「**Trivy Operator - Overview**」(uid `trivy-overview`) を使う。定義は `seichi-onp-k8s/manifests/seichi-kubernetes/apps/cluster-wide-apps/trivy-operator-dashboard/grafana-dashboard.yaml`。概要 (重大度別の検出数・ユニーク CVE 数・EOL ベース OS のイメージ数)、イメージ別、CVE 別 (影響イメージ数)、ワークロード別、EOL ベース OS、設定監査 / RBAC / インフラ / コンプライアンス / 公開シークレット、Operator のエラーログの順に並ぶ。

生のメトリクスをそのまま合計すると件数が実態より大きく見えるため、次の補正をしている。

- **Unknown の意味**: Operator はレポートの重大度を Trivy の `VendorSeverity[SeveritySource]` から取るので、ベンダー severity の無い CVE (Go の `stdlib` / `golang.org/x/*`、一部の GHSA 由来 JAR) は `Unknown` になり、全体の約 7 割を占める。`trivy.severity` で LOW は除外済みなので、Unknown は「MEDIUM 以上でベンダー評価なし」と読む。隠さずに独立した列・パネルとして表示する。
- **Go 標準ライブラリの増幅**: Go バイナリを含むイメージが多く、同じ stdlib の CVE が数百コンテナに出る。概要の行 (ユニーク CVE 数と重大度別の検出数) と CVE の表には「除外するパッケージ」変数が効き、既定で `stdlib` と `golang.org/x/*` を除外する。概要の重大度別の検出数は `trivy_vulnerability_id` から「CVE × パッケージ × イメージ」の組を数えるので、このトグルに追従する。イメージ別・ワークロード別の表はレポート上の件数 (`trivy_image_vulnerabilities`、パッケージ名なし) なのでトグルは効かない。
- **完了 Job の履歴**: mariadb-operator の Backup / Restore が残した完了 Job もレポートを持ち、同じイメージが数十件の Job に出る。イメージ単位の数字は registry/repository:tag@digest で重複排除し (同じタグでも digest が違えば別イメージ)、CVE の表は脆弱性 ID × パッケージごとの影響イメージ数を数える。ワークロード別の表と設定監査 (重大度別・リソース別) は「Job」変数 (既定は除外。実行中の Job も外れる) で Job を外している。CVE の表の重大度は、ディストリビューションごとに評価が分かれる場合に影響イメージ内の最大を Critical > High > Unknown (≥Medium) > Medium の順で出す。
- **同じイメージを複数 namespace で使う場合**: 概要の合計はイメージだけで重複排除し、`namespace` 変数で絞れる。

EOL ベース OS のパネルは `trivy_image_info` (`operator.metricsImageInfo: true` で出力) を使う。

dotdc の「Trivy Operator - Vulnerabilities」(uid `security_trivy_operator`、`grafana-dashboards-kubernetes` Application が配布) も Kubernetes フォルダに残っているが、上の補正をしていない生の件数なので参考程度にする。

脆弱性の対応 (どのイメージを上げるか、どの CVE を無視するか) は「Trivy Operator - Overview」を見て判断する。脆弱性の件数ではアラートを出さない。MEDIUM 以上の脆弱性はサードパーティイメージのどこかに常に存在するので、件数アラートは鳴りっぱなしで Discord に 4 時間ごとに再通知されるだけになるため。

## アラート

3 つのアラート (Prometheus ルール 2 つ + Loki ルール 1 つ) はいずれも `severity: warning` / `notify: discord`。スキャン基盤そのものの故障だけを通知する。

| アラート | 条件 | 対応 |
|---|---|---|
| `TrivyOperatorDown` | operator が 15 分以上 scrape できない | `kubectl -n trivy-operator get pods` で CrashLoopBackOff / OOMKilled / Pending を確認。OOMKilled なら Application の `resources.limits.memory` を上げる |
| `TrivyScanJobsFailing` (Loki ルール) | operator のエラーログ (`msg="Scan job container"`) が直近 2 時間に 3 件以上の状態が 30 分続く (取得できないイメージ 1 つで約 2 件/時) | Loki で `{job="trivy-operator/trivy-operator"} \| json \| level="error" \| msg="Scan job container"` を実行し、`status_message` 末尾の FATAL 行で原因を見る。取得できないイメージ (タグ削除、レジストリの rate limit)、DB / Java DB の取得失敗、Kyverno の webhook 停止、OOMKilled、タイムアウトが典型。失敗した Job は operator がすぐ消すので `kubectl get jobs` では見えない |
| `TrivyVulnerabilityReportsMissing` | operator は up なのに `trivy_image_vulnerabilities` が 2 時間以上無い | スキャンが 1 件も成功していない。`kubectl -n trivy-operator get jobs`、operator と `trivy-server` のログを確認 |

## チューニング

値はすべて Application の `helm.values` 内、`---- チューニング値 ----` で囲んだブロックにある。

- **再スキャン周期**: `operator.scannerReportTTL` (現在 72h)。レポートが期限切れになると再スキャンされる。短くすると新しい CVE に早く気付けるが、Java イメージごとに 942MiB の Java DB 取得が走る
- **同時実行数**: `operator.scanJobsConcurrentLimit` (現在 2)。2 並列で全クラスタ (117 イメージ) 約 27 分なので通常は上げる必要は無い。上げると 1 ジョブ最大 1Gi のメモリを並列分確保する。wk-2 / wk-3 のメモリ requests が逼迫している点に注意
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

## ノードと Kubernetes コンポーネントのスキャン

Trivy Operator が見るのはコンテナイメージとクラスタの設定までで、ノード自体の OS パッケージは見ない。これを補うものを `cluster-wide-apps/trivy-node-scanner` に置いている。ダッシュボードは Grafana の **Trivy** フォルダの「**Trivy - Nodes**」(uid `trivy-nodes`)。

| 対象 | 仕組み | 出力先 |
|---|---|---|
| ノードの OS パッケージ (dpkg) | DaemonSet `trivy-node-scanner` が 1 日 1 回 `trivy rootfs` を実行 | node-exporter の textfile collector → Prometheus (`trivy_node_*`) |
| Kubernetes コンポーネント (kubelet / apiserver / controller-manager / etcd / containerd 等) | CronJob `trivy-kbom` が毎日 05:30 JST に `trivy k8s --format cyclonedx` で KBOM を作り `trivy sbom` で照合 | 1 件 1 行の JSON ログ → Loki (`{job="trivy-operator/kbom"}`) |

### ノードの OS パッケージ

- ホストのルートはマウントせず、`/usr/lib/os-release`、`/etc/os-release`、`/etc/lsb-release`、`/var/lib/dpkg` だけを読み取り専用でマウントする。ルート全体を走査すると containerd のイメージ層まで読んで 512Mi で即 OOMKilled した。`/etc/lsb-release` が無いと Trivy は OS を判定できず 0 件になる
- 脆弱性 DB は Pod ごとに取得する (Standalone)。クラスタ内の trivy-server を使うと、旧カーネルの残骸があるノードの結果 (6 万件規模) をサーバーが処理しきれず、2 ノード同時で trivy-server が OOMKilled した
- 結果は「パッケージ × 重大度の件数」に集約して出す。CVE 単位だと 1 ノード 1 万系列を超える
- `kind` ラベルで 4 つに分ける。スクリプトが `uname -r` (コンテナはホストのカーネルを共有する) と比べて判定する

| `kind` | 意味 | 対応 |
|---|---|---|
| `package` | 通常のパッケージ | パッケージを更新する |
| `running-kernel` | 稼働中カーネルのパッケージ | 更新してノードを再起動する (kured) |
| `newer-kernel` | 稼働中より新しいカーネル (インストール済みで再起動待ち) | 再起動すると `running-kernel` になる。修正版が出ていれば更新する |
| `stale-kernel` | 動いていない旧カーネルの残骸 | `apt autoremove --purge` で消す。実害は無いが件数が大きく見える |

- 見方: ダッシュボードの「対応が必要な脆弱性」(`stale-kernel` を除いた件数) が 0 かどうかを見る
- スキャンが失敗したときは前回成功時の件数を残し、`trivy_node_scan_success` だけを 0 にする (0 件 = 問題なしに見えないように)。表示中の件数の古さは `trivy_node_last_success_timestamp_seconds` で分かる。失敗時は 1 時間後に再試行する
- Trivy は OS を判定できないと 0 件のまま正常終了するので、OS パッケージの結果が無いスキャンは失敗扱いにする
- 脆弱性 DB (展開後約 1.55GiB) はスキャンごとに消す。数時間おきに更新されるので、24h 後には再取得になるため
- textfile は Pod の停止時に消さない (再起動直後に 0 件に見えないように)。DaemonSet を撤去するときは各ノードの `/var/lib/node-exporter/textfile/trivy_node.prom` を手で消す

### Kubernetes コンポーネント (KBOM)

- Trivy Operator 本体にも KBOM 機能 (`ClusterVulnerabilityReport` の `k8s-cluster`) があるが、`operator.sbomGenerationEnabled: true` が必須で、全イメージの SbomReport も作られる。CycloneDX での実測は Minecraft イメージで約 860KB、debezium で約 1.9MB (etcd の 1 リクエスト上限 1.5MiB を超えて保存できない) で、全イメージ分を etcd に載せるのは重いので使わない
- `trivy-kbom` の権限は nodes / pods / namespaces の get / list だけ (ClusterRole `trivy-kbom`)。`--disable-node-collector` を付けているので Job は作らない
- KBOM の照合は Trivy Operator の trivy-server に任せる (結果は数件なのでサーバーの負荷にならず、Pod ごとの DB 取得も不要)
- Loki で直接見るとき:

```logql
{job="trivy-operator/kbom"} | json | event="trivy_kbom_vulnerability"
{job="trivy-operator/kbom"} | json | event="trivy_kbom_scan"
```

- 修正版が空のものは全バージョンが影響を受ける既知の問題で、Kubernetes を上げても消えない (例: CVE-2025-1767 は gitRepo ボリュームを使わなければ影響しない)

### アラート

| アラート | 条件 |
|---|---|
| `TrivyNodeScanFailing` | ノードのスキャンが失敗のまま 2 時間 (1 時間後の再試行でも直らない) |
| `TrivyNodeScanStale` | 最終成功から 2 日以上経った、または一度も成功していないノードがある状態が 3 時間 |
| `TrivyKbomScanFailing` (Loki) | 直近 1 日に KBOM スキャンの失敗があり、同じ期間に成功が無い状態が 15 分 (再試行で成功していれば鳴らない) |
| `TrivyKbomScanMissing` | CronJob `trivy-kbom` の最終成功から 2 日以上 (kube-state-metrics。一度も成功していない場合は作成から 2 日経つまで鳴らさない) |

## 既知の制約

- **レポートの severity が UNKNOWN になるものがある**: operator はレポートの severity を Trivy JSON の `VendorSeverity[SeveritySource]` から取る (`pkg/vulnerabilityreport/io.go`)。SeveritySource が無い脆弱性 (Go 標準ライブラリや GHSA 由来の JAR の CVE など、Trivy 自身は CVSS から MEDIUM / HIGH と表示するもの) は UNKNOWN になる。実証実験では debug lobby イメージの 92 件のうち 48 件 (Trivy 表示では MEDIUM 27 / HIGH 21) が UNKNOWN だった。`trivy.severity` のフィルタ自体は Trivy 側で効いている (LOW は入ってこない) ので、ダッシュボードやレポートの UNKNOWN は「未評価」ではなく「MEDIUM 以上だがベンダー severity が無い」と読むこと。upstream に修正 (VendorSeverity に無ければ Severity を使う) を出すのが本筋
- **古い Job のイメージは取得できないことがある**: 完了済みの Job が残っていると、そのイメージ (タグが upstream から消えたもの、レジストリの rate limit に当たるもの) を 30 秒ごとに pull しに行って失敗し続ける。実証実験では mariadb-operator の Restore が残した `mariadb-restore--*` と `sentry` namespace の `sentry-kafka-provisioning` がこれに当たったため、該当イメージを `trivyOperator.excludeImages` で (完全一致で) 除外している。元の Job / namespace を掃除したら除外は外せる
- **Java DB はスキャンジョブごとに取得される**: trivy-server が配信するのは本体の脆弱性 DB だけで、JAR を含むイメージをスキャンするたびにジョブ側で Java index DB (942MiB 圧縮、mirror.gcr.io から約 8 秒) をダウンロードする。本番 Minecraft イメージ 1 件のスキャンはこれを含めて約 25 秒。Minecraft 系の Java イメージが約 45 個あるので、再スキャン周期を短くするとそのぶん通信量が増える。Java DB の共有キャッシュ (RWX PVC + 定期更新) を作れば無くせるが、未実装
- **scanJobTTL は設定しない**: 理由は「チューニング」の項と Application のコメントを参照
- **Kyverno の webhook に依存する**: Kyverno の webhook は failurePolicy=Fail なので、Kyverno が落ちている間はスキャンジョブを作れない (`TrivyScanJobsFailing` / `TrivyVulnerabilityReportsMissing` の原因になり得る)
- **node-collector は root で動く**: hostPID と root、`/etc/kubernetes` などの read-only hostPath マウントが必要。`trivyOperator.scanJobPodTemplatePodSecurityContext` を設定すると node-collector にも適用されて動かなくなるので、空のままにする。PSA でこの namespace を restricted / baseline にすることもできない
- **レポートは Argo CD で管理されない**: operator が作るリソースなので、Argo CD の sync / prune の対象ではない。kubectl かダッシュボードで見る
- **ReplicaSet が変わるたびに再スキャンされる**: レポートは ReplicaSet 単位なので、Deployment の rollout (イメージ更新に限らず annotation の変更でも) のたびに新しい ReplicaSet がスキャンされる。Renovate の digest 更新が多い日はスキャンジョブも増える

## 実証実験 (2026-10-23)

本番クラスタの一時 namespace `trivy-operator-poc` に chart 0.37.0 を同じ values で展開して計測した (CRD 12 種は適用、残骸の ClusterRole と ClusterComplianceReport は SSA で上書き)。計測後に namespace `trivy-operator-poc` と ClusterRoleBinding `trivy-operator-poc` は削除済み。CRD 12 種、ClusterRole `trivy-operator`、ClusterComplianceReport 4 件、各 namespace のレポートは残してあり、本番の Application が引き取る。

| 項目 | 結果 |
|---|---|
| 全 namespace の初回スキャン (PR 環境除外、並列 2) | 約 27 分 (operator の再起動 2 回を含む)、VulnerabilityReport 255 件 / 117 イメージ |
| レポート量 | VulnerabilityReport 合計 8.9MB (最大 444KB = democratic-csi、895 件)、ConfigAuditReport 442 件 1.4MB、RbacAssessmentReport 83 件、InfraAssessmentReport 15 件 + ClusterInfraAssessmentReport 6 件 (control-plane 3 台も toleration で収集できた)、ClusterComplianceReport 4 件を更新。`apiserver_storage_size_bytes` は 273MiB → 274MiB |
| スキャンコンテナ | ピーク 380Mi / 1.2 コア、1 件 15〜30 秒。Java DB 942MiB を毎回取得 (約 8 秒) |
| operator / trivy-server | operator ピーク 459Mi、trivy-server 44〜90Mi。PVC 5Gi は既定 StorageClass (synology-iscsi-storage) に bind |
| Prometheus | ServiceMonitor で `up=1`、`trivy_image_vulnerabilities` 約 2,500 系列、`trivy_vulnerability_id` 約 30,800 系列 |
| Loki | operator のログは `{job="trivy-operator-poc/trivy-operator"}` で取れ、失敗ジョブのエラーログを `| json | level="error" | msg="Scan job container"` で数えられた (Loki ルールの根拠) |
| 検出件数 | CRITICAL 318 / HIGH 2306 / MEDIUM 1961 / UNKNOWN 12693 (UNKNOWN は「既知の制約」を参照)。EOL のベース OS を持つイメージが 24 件 (本番 Minecraft サーバー全台の ubuntu 20.04、synology-csi の debian 10 サイドカーなど) |
| Docker Hub の匿名 pull | クラスタの egress で 100 回 / 3600 秒 (ratelimit ヘッダの実測)。実証実験中は未到達 |

判明した問題と対処:

1. `scanJobTTL` を設定するとスキャンが止まる → 未設定にした
2. 古い Job のイメージが取得できず失敗し続ける → 該当する 2 イメージを `trivyOperator.excludeImages` で除外した (除外後に全 namespace を再スキャンして失敗ジョブ 0 を確認)
3. 2025 年の残骸レポートは TTL annotation が無く永久に更新されない (ClusterInfraAssessmentReport 6 / ClusterRbacAssessmentReport 218 / ClusterSbomReport 6 / ClusterVulnerabilityReport 6) → 2026-10-23 に削除した。実証実験で作った namespaced のレポート (TTL 72h 付き) は残してあり、TTL が切れるまでは本番の operator がそのまま使うので、導入直後に一斉スキャンは起きない
4. `trivy.timeout` を `operator.scanJobTimeout` と同じ 15m にしていたが、Job の deadline の方が先に来て Trivy のエラーがログに残らないため 13m に下げた (レビュー指摘)

## 経緯

- 2025-03〜2025-09 に Argo CD Application `trivy-operator` (chart 0.30.0) として導入されていたが、PR #3633 で理由の記載なく削除された
- 削除後もクラスタスコープのリソースが残っていた: cluster*reports の CRD 6 種 (namespaced の 6 種は削除されていた)、`argocd.argoproj.io/instance=trivy-operator` ラベル付きの ClusterRole / ClusterRoleBinding `trivy-operator`、owner の無い ClusterComplianceReport 4 件、ClusterRbacAssessmentReport 約 218 件
- 2026-10 に chart 0.37.0 で再導入した。Application 名と releaseName を当時と同じ `trivy-operator` にしたので、残っていた CRD 6 種と ClusterRole / ClusterRoleBinding はそのまま Argo CD の管理下に戻る (CRD のスキーマは 0.37.0 と同一)。namespaced の CRD 6 種は実証実験で作成済みで、これも Argo CD が引き取る。再発防止として Application に `resources-finalizer.argocd.argoproj.io` を付け、Application を消したときにチャートのリソースも消えるようにした。ClusterComplianceReport 4 件はチャートが同名で作るので引き継がれる。更新されないまま残っていたクラスタスコープのレポート (ClusterRbacAssessmentReport など) は 2026-10-23 に削除した
