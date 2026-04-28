# Minecraftサーバーと MariaDB databaseのロールバック

## 概要

整地鯖の主要 Minecraft サーバー（s1, s2, s3, s5, s7）の world データと、
MariaDB の業務 database（flyway, seichi-portal, seichi-timed-stats-conifers, seichiassist）を
バックアップ時点までロールバックする手順。

トラフィック遮断（メンテナンスモード）→ Argo Workflows でリストアジョブ実行 → 解除 → 動作確認、の流れ。

## 前提条件

- `seichi-onp-k8s` クラスタへの kubectl アクセス（tailscale 経由）
  - tailscale に接続したうえで、各コントロールプレーンノード
    (`seichi-onp-k8s-cp-{1,2,3}.seichi.internal`) に `cloudinit` ユーザーで SSH し、
    そこから `kubectl` を叩く運用（`*.seichi.internal` は tailscale 経由で名前解決される）
  - 例: `ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit -- kubectl -n seichi-minecraft get pods`
- Argo Workflows UI へのアクセス（GitHub SSO）
  - URL: <https://argo-workflows.onp-k8s.admin.seichi.click>
- Proxmox Backup Server (PBS) GUI へのアクセス（tailscale 経由）
  - URL: <https://sc-proxbksrv-01.ide-hadar.ts.net:8007/>
  - world データの復旧元バックアップ日時を確認するために使用
- メンテナンスモードの操作手順を把握していること（[maintenance-mode.md](./maintenance-mode.md)）

## ロールバック対象

| 種別 | 対象 | 備考 |
|------|------|------|
| Minecraft world | `mcserver--s1`, `mcserver--s2`, `mcserver--s3`, `mcserver--s5`, `mcserver--s7` | |
| MariaDB database | `flyway`, `seichi-portal`, `seichi-timed-stats-conifers`, `seichiassist` | Database CRD 名（namespace: `seichi-minecraft`） |

`mcserver--lobby`, `mcserver--votelistener`, `mcserver--kagawa`, `mcserver--one-day-to-reset` および coreprotect 系 database は本手順の対象外。

## バックアップ仕様

### Minecraft world (PBS)

- バックアップ先: Proxmox Backup Server `sc-proxbksrv-01`
- バックアップ ID: 各サーバー名と同名（例: `mcserver--s1`）
- バックアップアーカイブ名: `data.pxar`（`/data` ディレクトリ全体）
- スケジュール: `seichi-onp-k8s/manifests/seichi-kubernetes/apps/seichi-minecraft/workflows/mcserver-backup/cron-workflow.yaml` 参照
- 保持期間: PBS 側のデータストア設定に従う

### MariaDB database (Garage S3)

- バックアップ先: Garage S3 バケット `mariadb-backups`、prefix は `database--{Database CR名}`
- ワークフロー: `backup--mariadb-all-databases`（CronWorkflow）
- スケジュール: 毎日 **04:00 JST**
- 保持期間: 3 日（Backup CR / S3 オブジェクトともに自動削除）
- リストアは MariaDB Operator の `Restore` CRD によるポイントインタイムリカバリ

## 手順

### 1. メンテナンスモード有効化

[maintenance-mode.md](./maintenance-mode.md) の手順に従い、`maintenance-mode` ConfigMap の
`enabled` を `"true"` に変更して PR をマージ → ArgoCD で同期。

全 mcserver Pod が NotReady になり、Service エンドポイントから除外されたことを確認する：

```bash
ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit \
  'kubectl -n seichi-minecraft get pods | grep "^mcserver--"; \
   echo "---"; \
   kubectl -n seichi-minecraft get endpoints | grep "^mcserver--"'
```

対象 mcserver の Endpoints が空になっていれば OK。

### 2. PBS GUI で復旧元バックアップ日時を確認

PBS GUI (<https://sc-proxbksrv-01.ide-hadar.ts.net:8007/>) にログインし、
データストア配下の `host/mcserver--s{1,2,3,5,7}` から復旧元のバックアップを探す。
スナップショットのタイムスタンプ（例: `2026-04-28T19:00:00Z`）を控えておく。GUI の表示設定によってはローカルタイムが表示される場合があるが、ここでは UTC 形式の正確なスナップショット ID（Snapshot 列の値など）が必要となる。

UTC 表記で控え、後述の `RESTORE_TARGET_DATE_PBS` にそのまま渡す。

### 3. Minecraft world のロールバック実行

Argo Workflows UI から、対象サーバーごとに WorkflowTemplate を Submit する。

| WorkflowTemplate | namespace |
|------------------|-----------|
| `restore--mcserver--s1` | seichi-minecraft |
| `restore--mcserver--s2` | seichi-minecraft |
| `restore--mcserver--s3` | seichi-minecraft |
| `restore--mcserver--s5` | seichi-minecraft |
| `restore--mcserver--s7` | seichi-minecraft |

**パラメータ:**

| 名前 | 値 |
|------|-----|
| `RESTORE_TARGET_BACKUP_ID_PBS` | デフォルト（`mcserver--sN`）のままで OK。別バックアップ ID を使う場合のみ変更 |
| `RESTORE_TARGET_DATE_PBS` | 手順 2 で控えた UTC タイムスタンプ（例: `2026-04-28T19:00:00Z`） |

ワークフローは以下の順で実行される：

1. StatefulSet を `replicas=0` に縮退
2. Pod 停止待ち
3. PBS から `proxmox-backup-client` で `/data` を復元（既存ファイルは削除）
4. `plugins/*.jar` を削除（古い jar の混入を防ぐ）
5. StatefulSet を `replicas=1` にスケールアップ（5 分以内に Ready にならなければ失敗）

5 サーバーは独立しているので並列で Submit して構わない。

### 4. MariaDB database のロールバック実行

#### 4a. 事前準備: `slow_query_log` を OFF にする

リストア中は大量の SQL が流れて全クエリが MariaDB の slow log
(`long_query_time=0.1`) に乗り、`slow-log` emptyDir の `sizeLimit: 500Mi` を
超えて **`mariadb-0` Pod が `Evicted` される** 連鎖が起きる
（実際に発生し、複数の restore Job が `BackoffLimitExceeded` で失敗した実績あり）。

リストア開始前に slow log を OFF にして、既存ファイルも truncate しておく：

```bash
ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit \
  'kubectl -n seichi-minecraft exec mariadb-0 -c mariadb -- bash -c \
     "mariadb -u root -p\"\$MARIADB_ROOT_PASSWORD\" \
        -e \"SET GLOBAL slow_query_log=OFF; SHOW GLOBAL VARIABLES LIKE '\''slow_query_log'\'';\" \
      && : > /var/log/mysql/mysql-slow.log"'
```

#### 4b. ロールバック実行

Argo Workflows UI から `restore--mariadb--with-prefix`（namespace: `seichi-minecraft`）を、
対象 database ごとに 4 回 Submit する。

**パラメータ:**

| Database | `RESTORE_PREFIX` | `RESTORE_TARGET_DATE_DB` |
|----------|------------------|--------------------------|
| flyway | `database--flyway` | 復旧したい時刻（RFC3339, 例: `2026-04-28T19:00:00Z`） |
| seichi-portal | `database--seichi-portal` | 同上 |
| seichi-timed-stats-conifers | `database--seichi-timed-stats-conifers` | 同上 |
| seichiassist | `database--seichiassist` | 同上 |

`RESTORE_TARGET_DATE_DB` は MariaDB Operator の `targetRecoveryTime` に渡され、
指定時刻時点までの状態にポイントインタイムリカバリされる。

ワークフローは MariaDB Operator の `Restore` CRD を作成し、完了まで最大 1 時間（`activeDeadlineSeconds: 3600`）待機する。

#### 4c. 事後処理: `slow_query_log` を ON に戻す

手順 5 で全 DB の Restore が成功したことを確認したら、必ず ON に戻す：

```bash
ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit \
  'kubectl -n seichi-minecraft exec mariadb-0 -c mariadb -- bash -c \
     "mariadb -u root -p\"\$MARIADB_ROOT_PASSWORD\" \
        -e \"SET GLOBAL slow_query_log=ON; SHOW GLOBAL VARIABLES LIKE '\''slow_query_log'\'';\""'
```

### 5. 全ジョブの完了確認

#### MariaDB (`restore--mariadb--with-prefix`)

**重要:** workflow が `Succeeded` になっていても **実際は失敗している場合がある**。
`restore--mariadb--with-prefix` の `wait-complete-mariadb-restore` ステップは
Restore CR の `conditions[?(@.type=='Failed')].status` を見て失敗判定するが、
MariaDB Operator (v0.x 系) は失敗時も `type=Complete, status=True, message=Failed,
reason=JobFailed` を返す（`type=Failed` という condition は付与されない）ため、
失敗判定が空振りして workflow は誤って `Succeeded` になる。

必ず Restore CR 側で `STATUS` 列（= `message`）を直接確認する：

```bash
ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit \
  'kubectl -n seichi-minecraft get restore.k8s.mariadb.com'
```

`STATUS` が `Success` のものだけが本当に成功。`Failed` のものは workflow を
再 submit してリトライする（`generateName` を変えるだけで OK）。

Argo Workflows UI または CLI でも各 workflow を `Succeeded` を一応確認：

```bash
ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit \
  'kubectl -n seichi-minecraft get workflows --sort-by=.metadata.creationTimestamp | tail -20'
```

#### Minecraft world (`restore--mcserver--sN`)

**重要:** `wait-for-scale-to-1` ステップは StatefulSet の `.status.availableReplicas` が
`1` になるのを待つが、メンテモード ON 中は readinessProbe が必ず失敗するため
`availableReplicas` は 0 のまま増えない。よって本ステップは
`activeDeadlineSeconds: 300` の 5 分でタイムアウトし、**workflow 全体は `Failed` になる。**
これは想定挙動。

代わりに、各 mcserver の Pod ログを直接確認して Minecraft 本体が起動完了しているかを判断する：

```bash
ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit \
  'for n in s1 s2 s3 s5 s7; do
     echo "--- mcserver--$n-0 ---"
     kubectl -n seichi-minecraft logs mcserver--$n-0 -c minecraft --tail=200 \
       | grep -E "Done \(|ERROR|Exception" | tail -5
   done'
```

各サーバーで `Done (xx.xxs)! For help, type "help"` の行が出ていれば起動完了とみなす
（Pod 自体は Running、READY は `0/1` または `1/2` のままで問題なし）。
ERROR や Exception が出ていたらそのサーバーは別途調査が必要。

### 6. メンテナンスモード解除

[maintenance-mode.md](./maintenance-mode.md#メンテナンスモードの無効化) の手順に従い、
`enabled` を `"false"` に戻す PR をマージ → ArgoCD で同期。

### 7. 動作確認

- Pod が Ready になっていること

  ```bash
  ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit \
    'kubectl -n seichi-minecraft get pods | grep "^mcserver--s"'
  ```

  対象の s1, s2, s3, s5, s7 すべてで READY が `2/2`（または該当数）になっていること。

- Service Endpoints に Pod IP が戻っていること

  ```bash
  ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit \
    'kubectl -n seichi-minecraft get endpoints | grep "^mcserver--s"'
  ```

- 実際にゲームクライアントから各サーバーに接続できること
- ロールバック対象の database のテーブル件数や代表的なレコードがロールバック先時点の値になっていること
  （例: `seichiassist` の `playerdata` から数件抽出して期待値と一致するか確認）

## 注意事項

- **メンテナンスモード ON 中は毎日 04:00 JST の MariaDB バックアップ Cron がスキップされる。**
  ロールバックが長時間にわたって 04:00 JST を跨ぐ場合、その日のバックアップは作成されない。なお、現在の実装ではワークフローがエラー（Failed）として終了するため、Discord 等に失敗通知が飛ぶ点に留意すること。
- MariaDB バックアップ本体（Garage S3 上の `database--{name}` prefix）の保持期間は 3 日。
  `targetRecoveryTime` は秒単位の point-in-time recovery ではなく、指定時刻以前で最新の
  フルバックアップを採用する仕組み（MariaDB CR で binlog を有効化していないため）なので、
  **実質「日次精度」のロールバック**となる。
- 通常経路では 3 日より前の状態には戻せない。なお Garage S3 自体は毎日 10:00 JST に
  Proxmox Backup Server へ二次バックアップされており（`backup--garage-to-pbs`、ID `garage`）、
  原理的には PBS 保持期間内の任意日時へ巻き戻せる。ただし既存の `restore--garage-from-pbs`
  ワークフローは Garage 全バケットを sync で上書きするため、特定 prefix だけを復元する
  手段は本リポジトリに未整備。緊急時に必要となれば別途手順設計が必要。
- world ロールバックは `plugins/*.jar` を削除する。プラグイン jar は ConfigMap / initContainer で
  再配置される設計なので、StatefulSet の起動シーケンスが正常に走れば自動的に補充される。
- StatefulSet のスケールアップ待ちは 5 分でタイムアウトする。Pod が立ち上がらない場合は手動調査が必要。
- `restore--mcserver--sN` の最終ステップ `wait-for-scale-to-1` は `availableReplicas` を見ているため、
  **メンテナンスモード ON 中は readinessProbe が失敗し続けて必ずタイムアウト → workflow が `Failed` になる**。
  これは想定挙動なので、起動成否は手順 5 のとおり Pod ログ (`Done (xx.xxs)! For help, type "help"`) で判定する。
- mcserver の world と coreprotect database は対になっているケースがあるため、world をロールバックした
  サーバーに対応する coreprotect database（例: `coreprotect-s1`）も合わせてロールバックすべきか
  別途検討する（本手順の対象外）。不整合が問題になる場合は、`restore--mariadb--with-prefix` を用いて該当の prefix をリストアすることを検討してください。
- **MariaDB の slow log は restore 中に必ず evict 連鎖を起こす**（`long_query_time=0.1` で全クエリが
  記録される設定 + emptyDir `sizeLimit: 500Mi`）。手順 4a / 4c で
  `slow_query_log` を OFF / ON する暫定回避を必須とする。
  恒久対策候補: `myCnf` から `slow_query_log` を削除する、`sizeLimit` を引き上げる、
  Operator の Restore Job spec に `slow_query_log=OFF` を強制する、など。
- **`restore--mariadb--with-prefix` の `wait-complete-mariadb-restore` の判定ロジックには
  既知のバグがある**: MariaDB Operator は失敗時 `type=Complete, status=True, message=Failed` を
  返すため、`type=Failed` のみを見ている現行ロジックでは失敗を検知できない。
  workflow が Succeeded でも Restore CR の `STATUS` が `Failed` でないかを必ず手動確認する。
  恒久対策候補: workflow 側で `conditions[?(@.type=='Complete')].message` も `Success` か
  チェックするように修正。

## 関連リンク

- [maintenance-mode.md](./maintenance-mode.md) — メンテナンスモード操作手順
- [restore--mcserver--s1 WorkflowTemplate](https://github.com/GiganticMinecraft/seichi_infra/blob/main/seichi-onp-k8s/manifests/seichi-kubernetes/apps/seichi-minecraft/mcserver--s1/argo-workflows-restore.yaml)
- [restore--mariadb--with-prefix WorkflowTemplate](https://github.com/GiganticMinecraft/seichi_infra/blob/main/seichi-onp-k8s/manifests/seichi-kubernetes/apps/seichi-minecraft/mariadb/argo-workflows-restore.yaml)
- [backup--mariadb-all-databases CronWorkflow](https://github.com/GiganticMinecraft/seichi_infra/blob/main/seichi-onp-k8s/manifests/seichi-kubernetes/apps/seichi-minecraft/mariadb/argo-workflows-backup-all-databases.yaml)
- [Argo Workflows UI](https://argo-workflows.onp-k8s.admin.seichi.click)
- [Proxmox Backup Server GUI](https://sc-proxbksrv-01.ide-hadar.ts.net:8007/)
