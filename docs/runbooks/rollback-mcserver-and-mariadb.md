# Minecraftサーバーと MariaDB databaseのロールバック

## 概要

整地鯖の主要 Minecraft サーバー（s1, s2, s3, s5, s7）の world データと、
MariaDB の業務 database（flyway, seichi-timed-stats-conifers, seichiassist）を
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
| MariaDB database | `flyway`, `seichi-timed-stats-conifers`, `seichiassist` | Database CRD 名（namespace: `seichi-minecraft`） |
| MariaDB database（任意） | `coreprotect-s1`, `coreprotect-s2`, `coreprotect-s3`, `coreprotect-s5`, `coreprotect-s7` | world を戻すサーバーに対応するもの。ブロック変更履歴を world と揃えたい場合や、coreprotect 側にも破損がある場合に戻す |

`mcserver--lobby`, `mcserver--votelistener`, `mcserver--kagawa`, `mcserver--one-day-to-reset` および `coreprotect-lobby`、`luckperms`、`litebans`、`seichi-portal` の database は本手順の対象外。

プレイヤーはサーバー間でアイテムを移動できる（共有インベントリ、4 次元ポケット、マインスタック等は `seichiassist` に保存される）ため、
一部のサーバーだけを戻すとアイテムの複製や消失が起きる。**原則として全サーバーと `seichiassist` を同じ時点に揃えて戻す。**

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
- 保持期間: S3 オブジェクトは **DB（prefix）ごとに最新 14 件**、Backup CR は 3 日で自動削除
  （`backup--mariadb-all-databases` の `KEEP` / `RETENTION_DAYS`）
  - つまり通常経路で戻せるのは直近 2 週間程度。ロールバック先のダンプが自動削除される前に作業できない場合は、
    手順 0 のとおり別 prefix へ退避しておく
- リストアは MariaDB Operator の `Restore` CRD によるポイントインタイムリカバリ

## 手順

### 0. 事前準備

#### 0a. ロールバック先のダンプを退避する（作業まで日が空く場合）

`database--{name}` の古いダンプは日次バックアップ（04:00 JST）のたびに消えていく。
作業までに次の日次バックアップを跨ぐ場合は、Garage の `mariadb-backups` バケット内で
ロールバック先のダンプを別 prefix（例: `incident-YYYYMMDD--database--{name}/`）にコピーしておく。
別 prefix は自動削除の対象外なので、手順 4b の `RESTORE_PREFIX` にその prefix を指定すればよい。
作業完了後、落ち着いたら退避した prefix を削除する。

- `aws s3 cp` で大きいオブジェクトをコピーすると `GetObjectTagging` が呼ばれ、Garage が
  NotImplemented を返して失敗する。`--copy-props none` を付ける。

#### 0b. 投票データを保存する（補填用）

ロールバックで、カット以降に受け付けた投票（`seichiassist.vote`）も消える。
後で補填するため、メンテナンスモード有効化後・ロールバック前に `vote` テーブルを保存しておく（手順 8）：

```bash
ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit \
  'kubectl -n seichi-minecraft exec mariadb-0 -c mariadb -- bash -c \
     "mariadb-dump -u root -p\"\$MARIADB_ROOT_PASSWORD\" seichiassist vote" \
     > ~/vote-before-rollback-$(date +%Y%m%d).sql'
```

#### 0c. 作業時間帯

- 所要時間の目安（2026-10 の実績）: world の復元 約 1 時間（s1 が最大）、
  DB の復元は `flyway` / `seichiassist` / `seichi-timed-stats-conifers` / `coreprotect-*` 合計で約 3 時間
  （`coreprotect-s5` の約 9GB のダンプが律速。`seichiassist` 約 1.5GB だけでも 1 時間以上かかる）
- 日次バックアップ（04:00 JST）と kured のノード再起動の時間帯（05:00〜07:00 JST）に掛からないようにする

### 1. メンテナンスモード有効化

[maintenance-mode.md](./maintenance-mode.md) の手順に従い、`maintenance-mode` ConfigMap の
`enabled` を `"true"` に変更して PR をマージ、Argo CD の
`seichi-minecraft-maintenance-mode` Application を手動Sync。

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

Argo Workflows UI または kubectl から、対象サーバーごとに WorkflowTemplate を Submit する。

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

kubectl から Submit する場合の例：

```bash
ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit '
for spec in "s1 2026-04-28T19:01:03Z" "s2 2026-04-28T19:01:17Z"; do  # サーバー名と手順 2 の値
  set -- $spec
  cat <<EOF | kubectl create -f - -o name
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: restore--mcserver--$1-
  namespace: seichi-minecraft
spec:
  workflowTemplateRef:
    name: restore--mcserver--$1
  arguments:
    parameters:
      - name: RESTORE_TARGET_DATE_PBS
        value: "$2"
EOF
done'
```

- **`RESTORE_TARGET_DATE_PBS` は必ず指定する。** 空のままだと `/data` を削除した後に
  `proxmox-backup-client` がスナップショットパスを解釈できずに失敗し、**データだけが消えた状態**になる。
- **Workflow 側に `spec.serviceAccountName` を書かない。** Secure templateReferencing が有効なため
  `fields [ServiceAccountName] are not permitted when using workflowTemplateRef` で即 Error になる
  （SA は WorkflowTemplate 側に `mcserver--sN-workflow-sa` が設定済み）。

#### 3a. world の復元後、DB の復元が終わるまで mcserver を止める

world の Workflow は最後に StatefulSet を `replicas=1` に戻して mcserver を起動する。
起動した mcserver が復元途中の DB に触る（SeichiAssist 起動時の flyway、CoreProtect の書き込みなど）のを避けるため、
手順 5 の要領で `Done (` を確認したら、DB の復元が終わるまで止めておく：

```bash
ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit \
  'for n in s1 s2 s3 s5 s7; do kubectl -n seichi-minecraft scale sts mcserver--$n --replicas=0; done'
```

DB の復元と確認（手順 4・5）が終わったら `--replicas=1` に戻し、再度 `Done (` を確認する。
（ArgoCD の sync window 外であれば、手動で変えた replicas が勝手に戻されることはない）

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

Argo Workflows UI または kubectl から `restore--mariadb--with-prefix`（namespace: `seichi-minecraft`）を、
対象 database ごとに Submit する。

**パラメータ:**

| Database | `RESTORE_PREFIX` | `RESTORE_TARGET_DATE_DB` |
|----------|------------------|--------------------------|
| flyway | `database--flyway` | 復旧したい時刻（RFC3339, 例: `2026-04-28T19:00:00Z`） |
| seichi-timed-stats-conifers | `database--seichi-timed-stats-conifers` | 同上 |
| seichiassist | `database--seichiassist` | 同上 |
| coreprotect-sN（任意） | `database--coreprotect-sN` | 同上 |

`RESTORE_TARGET_DATE_DB` は MariaDB Operator の `targetRecoveryTime` に渡され、
指定時刻時点までの状態にポイントインタイムリカバリされる。

ワークフローは MariaDB Operator の `Restore` CRD を作成し、完了まで最大 1 時間（`activeDeadlineSeconds: 3600`）待機する。
大きい DB（`coreprotect-*`、`seichiassist`）は 1 時間を超えるため **workflow は `Failed` になるが、Restore 自体は続行する**。
成否は手順 5 のとおり Restore CR の `STATUS` で判定する。

kubectl から Submit する場合の例：

```bash
ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit '
for db in flyway seichiassist seichi-timed-stats-conifers; do
  cat <<EOF | kubectl create -f - -o name
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: restore--mariadb--with-prefix-
  namespace: seichi-minecraft
spec:
  workflowTemplateRef:
    name: restore--mariadb--with-prefix
  arguments:
    parameters:
      - name: RESTORE_PREFIX
        value: "database--$db"
      - name: RESTORE_TARGET_DATE_DB
        value: "2026-04-28T20:00:00Z"
EOF
  sleep 4
done'
```

- **Submit は数秒ずつ間隔を空ける。** Restore CR 名は `mariadb-restore--YYYYMMDD-HHMMSS`（秒単位）なので、
  同じ秒に 2 本投げると名前が衝突する。
- 並列で投げてよい（2026-10 は 8 本並列で問題なかった）。
- どのダンプが採用されたかは、Restore Job の Pod ログで確認できる：

  ```bash
  ssh seichi-onp-k8s-cp-1.seichi.internal -l cloudinit \
    'for p in $(kubectl -n seichi-minecraft get pods -o name | grep mariadb-restore--); do
       kubectl -n seichi-minecraft logs $p --all-containers | grep -m1 "Restoring backup"
     done'
  ```

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

**`/data/eula.txt: Input/output error` などで CrashLoopBackOff になる場合:**
restore Pod と mcserver Pod が同じノードに載ると、synology-csi の unstage / stage が競合し、
mcserver Pod が「iSCSI セッションが切られた後の古いデバイス」をマウントしたままになることがある
（2026-10 に s7 で発生。ノードの dmesg に `BTRFS error (device sdX): bdev /dev/sdX errs: wr 0, rd N` が出続け、
`/sys/block/sdX` が存在しない）。データは restore Pod の umount 時に書き込み済みなので、
StatefulSet を `replicas=0` → ボリュームの切り離し（`kubectl get volumeattachment` から消える）を待つ → `replicas=1` で直る。

### 6. メンテナンスモード解除

[maintenance-mode.md](./maintenance-mode.md#メンテナンスモードの無効化) の手順に従い、
`enabled` を `"false"` に戻す PR をマージ、Argo CD の
`seichi-minecraft-maintenance-mode` Application を手動Sync。

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
- （破損からの復旧の場合）破損していたファイル・テーブルが読めること
  - world: ノード上で `cat <file> > /dev/null` がエラーにならない
  - DB: `CHECKSUM TABLE <table>` が最後まで通る（`SELECT COUNT(*)` はインデックスだけで済む場合があるので全件読みの確認にならない）
- ロールバック対象の database のテーブル件数や代表的なレコードがロールバック先時点の値になっていること
  （例: `seichiassist` の `playerdata` から数件抽出して期待値と一致するか確認）

### 8. 投票の補填

手順 0b で保存した `vote` テーブルと現在の `vote` テーブルを比較し、カット以降に投票したプレイヤーの
**`vote_number`・`chain_vote_number`・`last_vote` の 3 列だけ**を保存時の値に戻す。

- SeichiAssist は投票受付時（`/vote record`）に `vote_number` +1 と `chain_vote_number` / `last_vote` の更新だけを行い、
  特典（ガチャ券・アイテム・`effect_point` +10）はプレイヤーがメニューから受け取る時に
  `vote_number - given_effect_point` 分を付与して `given_effect_point` を進める。
- `effect_point` と `given_effect_point` はロールバック後の値のまま触らない。これで、カット以降の投票分が
  「未受け取り」になり、プレイヤーが特典を受け取り直せる。カット以降に受け取った特典のアイテムはロールバックで
  消えているが、`given_effect_point` も戻っているので二重付与にはならない。
- 適用前に現在の `vote` テーブルも保存しておく。UPDATE には `AND vote_number=<現在値>` を付け、
  1 トランザクションで流して更新件数が想定と一致した場合だけ COMMIT する。
- メンテナンスモード中で誰もログインしていない間に行う。

## 注意事項

- **メンテナンスモード ON 中は毎日 04:00 JST の MariaDB バックアップ Cron がスキップされる。**
  ロールバックが長時間にわたって 04:00 JST を跨ぐ場合、その日のバックアップは作成されない。なお、現在の実装ではワークフローがエラー（Failed）として終了するため、Discord 等に失敗通知が飛ぶ点に留意すること。
- MariaDB バックアップ本体（Garage S3 上の `database--{name}` prefix）は DB ごとに最新 14 件だけ残る。
  `targetRecoveryTime` は秒単位の point-in-time recovery ではなく、指定時刻以前で最新の
  フルバックアップを採用する仕組み（MariaDB CR で binlog を有効化していないため）なので、
  **実質「日次精度」のロールバック**となる。
- 通常経路では直近 14 件より前の状態には戻せない（必要なら手順 0a で事前に退避する）。なお Garage S3 自体は毎日 10:00 JST に
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
- mcserver の world と coreprotect database は対になっているため、world をロールバックした
  サーバーに対応する coreprotect database（例: `coreprotect-s1`）も合わせてロールバックするか検討する。
  戻さない場合、world には存在しないブロック変更の履歴が coreprotect に残る。
  戻す場合はダンプが大きく（数 GB〜10GB 程度）、復元に数時間かかる点に注意（手順 0c）。
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
- `seichi-portal` の DB も、`restore--mariadb--with-prefix` の workflow でロールバックを行えるが、ゲームサーバのデータとは直接関係ないので、本手順では対象外としている。


## 関連リンク

- [maintenance-mode.md](./maintenance-mode.md) — メンテナンスモード操作手順
- [restore--mcserver--s1 WorkflowTemplate](https://github.com/GiganticMinecraft/seichi_infra/blob/main/seichi-onp-k8s/manifests/seichi-kubernetes/apps/seichi-minecraft/mcserver--s1/argo-workflows-restore.yaml)
- [restore--mariadb--with-prefix WorkflowTemplate](https://github.com/GiganticMinecraft/seichi_infra/blob/main/seichi-onp-k8s/manifests/seichi-kubernetes/apps/seichi-minecraft/mariadb/argo-workflows-restore.yaml)
- [backup--mariadb-all-databases CronWorkflow](https://github.com/GiganticMinecraft/seichi_infra/blob/main/seichi-onp-k8s/manifests/seichi-kubernetes/apps/seichi-minecraft/mariadb/argo-workflows-backup-all-databases.yaml)
- [Argo Workflows UI](https://argo-workflows.onp-k8s.admin.seichi.click)
- [Proxmox Backup Server GUI](https://sc-proxbksrv-01.ide-hadar.ts.net:8007/)
