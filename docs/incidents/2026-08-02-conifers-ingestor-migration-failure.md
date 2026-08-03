# 2026-08-02 seichi-timed-stats-conifers ingestor 全滅インシデント

ポストモーテム草稿(セッション間クロスレビュー 3 巡を反映済み)。検証に必要な再現手順と関連出力の抜粋は付録に含む。
恒久対策とポストモーテム完了タスクは個別 issue で追跡する(個人アサインは issue 側で行う)。

## TL;DR

- **事象**: 5 分ごとの ingest CronJob が [06:45, 14:50) UTC の約 8 時間停止。**97 回の予定実行がデータを生成せず**、欠損点は各統計系列 97 点・4 系列合計 388 点(実測)
- **故障機構(確定)**: migration init コンテナ (diesel_cli) が適用済みの初回マイグレーションを未適用と判定して再実行し、`Table 'break_count_full_snapshot_point' already exists` で exit 1。ingestor 本体は一度も起動せず
- **最有力の技術的原因(強く支持される推論)**: イメージ再ビルドで入った bookworm のクライアント実行環境(最有力は動的リンクの libmariadb `1:10.11.18-0+deb12u1`)が、MariaDB 11.8 サーバーとの組合せで適用済みマイグレーション一覧の取得を壊す。base を trixie(libmariadb `1:11.8.6-0+deb13u1`)に変えるだけで解消することを対照実験と本番復旧で確認
- **運用上の原因(別立て)**: 無関係なアプリ変更で migration イメージまで再ビルド・再配備される構造/base・APT パッケージ・CLI が全て浮動/5 分ごとの全実行に migration init を通す設計(影響拡大要因)
- **状態**: 応急対応済み・復旧確認済み。恒久対策は採用決定済み・未実施(実施計画と追跡 issue を後述)

## システム構成(前提)

- アプリ repo: `GiganticMinecraft/seichi-timed-stats-conifers`(Rust)。マイグレーションは 1 個のみ: `server/database/migrations/20230524025310_create_initial_tables`(事故当時の名称 `2023-05-24-025310_create_initial_tables`)
- migration イメージ (`server/Dockerfile-database-migration`): rust:slim base に `cargo install diesel_cli`(**事故当時バージョン未固定**)、`default-libmysqlclient-dev`(Debian の libmariadb)を動的リンク。ENTRYPOINT で `diesel migration run`
- ingestor イメージ: diesel-async 0.9.0 (mysql_async, 純 Rust) + distroless/cc。libmysqlclient 非依存(Cargo.lock に mysqlclient-sys なし)
- インフラ repo: `GiganticMinecraft/seichi_infra`。CronJob 定義 `.../seichi-timed-stats-conifers/ingestor-cronjob.yaml`(sha タグ + digest ピン)。ArgoCD auto-sync
  - 注: digest ピンは「配備されるイメージ内容」を固定するだけで、**再ビルド時に別の依存物が入ることは防がない**
- DB: クラスタ内 MariaDB **11.8.8** (x86_64)。DB/ユーザー名 `seichi-timed-stats-conifers`
- CronJob: `*/5 * * * *`, concurrencyPolicy: Replace, activeDeadlineSeconds: 240, backoffLimit: 5

## タイムライン(2026-08-02、JST = UTC+9)

| 時刻 (JST) | 出来事 |
|---|---|
| (2025-04-26) | DB 初期化。当時の migration イメージ (diesel_cli 2.1.0 / libmariadb 1:10.11.3-1、2023 年ビルド) が `__diesel_schema_migrations` に version `20230524025310`(ハイフン除去形式)を記録 |
| 15:11 | アプリ PR #196 merge (ee9e979): Sentry 撤去 + Pyroscope push。CI が sha-ee9e979 をビルド → diesel_cli 2.1.0→**2.3.11**、libmariadb 1:10.11.3-1→**1:10.11.18-0+deb12u1** に一斉更新 |
| 15:40 | 旧イメージ (sha-9cb78a5) での最後の成功実行 |
| 15:41 | seichi_infra PR #5674 merge → sync。migration/ingestor イメージが sha-ee9e979 に |
| 15:45〜 | 全実行が失敗開始。job_name ごとにアラートが fire/resolve を繰り返し Discord 通知が断続的に連発 |
| 16:00 頃 | 最初の ConifersIngestorJobFailed 通知 |
| 17:50 頃 | mariadb-0 再起動(別件 PR #5671 の反映。失敗開始の 2 時間後であり無関係と判断) |
| 22:40 頃 | 調査開始(**最初の通知から約 6 時間 40 分**。空白の理由は推測で埋めず、当日対応者=本ポストモーテムの調査オーナーが記入する) |
| 23:02 | アプリ PR #197 merge (8cf3333): 当初仮説「版数ハイフン形式差」に基づくリネーム + diesel_cli 2.3.11 固定。infra PR #5681 で反映するも**失敗継続** → 仮説棄却 |
| 23:15-30 | デバッグ Pod・DB 精査・上流 issue 調査・ライブラリ差分特定・ローカル対照実験(付録) |
| 23:35 | アプリ PR #198 merge (5fe5b38): base を rust:1.97.1-slim-**trixie** に変更 |
| 23:41 | infra PR #5682 merge → 23:45:51 sync |
| 23:50 | Job 29761370 成功、復旧確認(lastSuccessfulTime 14:50:52Z) |
| 翌 00:00 頃 | 付随対応: アラート通知改善 PR #5683 反映(通知テンプレート修正 + ルール単一インスタンス化) |

## 因果の整理(4 層)

1. **起点(トリガー)**: マイグレーションと無関係なアプリ変更 (Sentry 撤去) で、同一 repo/CI に同居する migration イメージまで再ビルド・再配備された
2. **潜在欠陥**: base イメージ(の APT パッケージ)と diesel_cli がいずれも「ビルド日の最新」を拾う構造。同じソースでも再ビルドで依存物一式が変わる。前回ビルド (2023) から 3 年分の差分が一度に入った
3. **故障機構**: 適用済みマイグレーションの version を正常に取得できず、適用済み DDL を再実行 → テーブル衝突で init 失敗
4. **影響拡大要因**: 5 分ごとの全 ingest 実行の init に migration を置いているため、migration の依存障害がそのまま全 ingest 停止に直結した

## 事実の確度分類

### 確定事項(観測済み)

- init コンテナのログ: `Running migration 20230524025310_create_initial_tables` → `Table 'break_count_full_snapshot_point' already exists` で exit 1(sha-8cf3333 時点。版数文字列は DB 記録と完全一致した状態で再実行している)
- DB 側の記録は正常: version=`20230524025310`(HEX で純 ASCII 14 桁・不可視文字なし)、DDL 正常、アプリユーザーは対象 DB に `GRANT ALL`(付録 B)
- 新イメージ内で `diesel migration list` → `[ ]`(未適用判定)、exit 0(付録 B)。**注: これで確定するのは「未適用判定に至った」ことまで。**「空文字列として読まれた」は後述の推論
- バージョン差分: 旧イメージ = diesel_cli 2.1.0 + libmariadb 1:10.11.3-1 / 新 = 2.3.11 + 1:10.11.18-0+deb12u1(dpkg で確認、付録 B)
- 対照実験(付録 A): 同一 Dockerfile 手順で base だけ変えた 2 つの動的リンクビルド(いずれも diesel_cli 2.3.11)が、同一の MariaDB 11.8・同一データに対して bookworm=`[ ]` 誤判定 / trixie=`[X]` 正常
- trixie ベースのイメージ投入で本番が復旧した

### 強く支持される推論

- bookworm と trixie の**クライアント実行環境の差**が原因であり、その最有力候補は libmariadb(1:10.11.18-0+deb12u1 ⇔ 1:11.8.6-0+deb13u1)である
  - 限界: 対照実験は base 丸ごとの差し替えであり、OpenSSL/glibc/ビルド時ヘッダ・ツールチェーン差も同時に変わっている。また実験は arm64(Apple Silicon 上のコンテナ)、本番は amd64。**libmariadb 単体の確定には、同一バイナリ・同一 OS で .so だけ差し替える実験か、Connector/C の最小再現プログラムが必要(未実施)**
- 上流の関連報告: diesel-rs/diesel#5102 (2026-07-02)。**同一とは言えないが強く関連**。要旨: (a) 配布版 diesel CLI(bundled ビルド)は正常、(b) アプリ内の同期 MysqlConnection + MigrationHarness では取得した適用済み一覧の**先頭行が空文字列** `MigrationVersion("")` になる、(c) 報告者が diesel CLI を動的リンク (`--features mysql`) で**再ビルドすると CLI でも同症状が再現**、(d) `mysql-bundled` に切り替えると解消、(e) サーバーを MariaDB 11.4.12→10.11 に下げても解消。maintainer は「upstream regression の duplicate(参照先 #5091 は GitHub 上 404)、MariaDB は非サポート」としてクローズ。我々の CLI も動的リンクビルドであり (c) の構成に一致する

### 未検証仮説

- 我々の経路でも「version が空文字列として読まれた」という具体機構(#5102 の (b) からの類推。我々は読み取り値そのものを観測していない)
- 症状の正確な範囲: 全行か先頭行のみか、どの結果バインド経路が壊れるのか。**仮に文字列読み出しが広範に壊れるなら、動的リンクの他サービスが存在した場合はデータ破壊を伴い得るため、範囲特定は横展開判断に直結する**(現時点でクラスタ内の該当構成は conifers migration のみ、付録 C)
- trixie の libmariadb が「バグ未混入」なのか「修正済み」なのか(将来の deb13uX での再発可能性評価に必要)
- サーバー側条件の寄与(#5102 ではサーバーダウングレードでも解消しており、client/server の組合せ条件は不明)

## 影響と検知の評価

- 失敗区間: [06:45, 14:50) UTC。影響件数は 2 種類に分けて数える:
  - **データを生成しなかった予定実行: 97 回**(concurrencyPolicy: Replace により途中置換された Job があるため、「97 個の Job が失敗」ではなくこの表現が正確)
  - **欠損データ点: 各統計系列 97 点、4 系列 (break/build/play_ticks/vote) 合計 388 点**(全系列で区間内 0 行を実測)
- ingestor は一度も起動していないため、壊れた可能性のあるライブラリ経由でのデータ書き込みは発生していない(migration ゲートでの停止は結果的に書き込み事故を防いだ)
- **欠損の実測**(2026-08-03 00:15 UTC 時点、各 `*_diff_point` の行数で確認):
  - 平常時は 12 行/時(5 分間隔)。事故当日は 06 時台 9 行 → **07〜13 時台が完全に 0 行** → 14 時台 2 行(14:50 から再開)。4 系列すべてで区間 [06:45, 14:50) は 0 行、15 時台は 12 行に復帰
  - 復旧後の追従: 14:50 の復旧点から 5 分間隔の記録が翌日 00:15 UTC まで連続していることを確認(実測で言えるのはここまで)。diff は取得した現在値をそのまま `new_value` に挿入する実装([has_tables_impl.rs#L148](https://github.com/GiganticMinecraft/seichi-timed-stats-conifers/blob/5fe5b38/server/infra/db_repository_impl/src/diesel_based_impl/has_tables_impl.rs#L148)、スキーマは [up.sql](https://github.com/GiganticMinecraft/seichi-timed-stats-conifers/blob/5fe5b38/server/database/migrations/20230524025310_create_initial_tables/up.sql) の `new_value bigint unsigned not null`)のため、復旧後の系列は取得元の現在値を反映する。**取得元(ゲームサーバー API)との値の突合は未実施**。失われたのは期間中の 5 分粒度の中間点のみ
  - バックフィル: **現在の ingest 元(ゲームサーバーの現在値 API)と保持データからは再構成不能**。欠損点は一度もどこにも書き込まれていないため DB バックアップにも存在しない。ゲームサーバー側に別の履歴源(ログ等)があるかは**未調査**
  - 利用者影響: 当該 8 時間分の粒度データを使う表示(期間集計・推移)に空白が出る。影響画面・集計単位・表示上の挙動の列挙は [#5694](https://github.com/GiganticMinecraft/seichi_infra/issues/5694) で追跡
- 検知の課題:
  - 最初の通知から調査開始まで約 6 時間 40 分(経緯の記録は [#5695](https://github.com/GiganticMinecraft/seichi_infra/issues/5695) で追跡)。job_name ごとの fire/resolve 連発が認知を阻害した可能性(通知形式は PR #5683 で改善済み)
  - 現行アラートは「失敗 Job の存在」の検知であり、成功の途絶そのものを見ていない。**「最後の成功からの経過時間」の監視を追加すべき**(例: `time() - kube_cronjob_status_last_successful_time{cronjob="seichi-timed-stats-conifers-ingestor"} > 1800`、または統計データ鮮度の直接監視)

## 実施済み対応(応急)

| PR | 内容 | 位置づけ |
|---|---|---|
| アプリ [#197](https://github.com/GiganticMinecraft/seichi-timed-stats-conifers/pull/197) | 版数ディレクトリをハイフン無しにリネーム + diesel_cli 2.3.11 固定 | 当初仮説(棄却済み)に基づく変更だが無害であり、CLI 浮動の解消として維持 |
| アプリ [#198](https://github.com/GiganticMinecraft/seichi-timed-stats-conifers/pull/198) | base を rust:1.97.1-slim-trixie に変更 | 故障機構の回避。復旧を確認 |
| インフラ [#5681](https://github.com/GiganticMinecraft/seichi_infra/pull/5681) / [#5682](https://github.com/GiganticMinecraft/seichi_infra/pull/5682) | 上記イメージの反映 | — |
| インフラ [#5683](https://github.com/GiganticMinecraft/seichi_infra/pull/5683) | アラート通知テンプレート修正 + ルール単一インスタンス化 | 検知課題の一部(通知可読性)に対応 |

trixie 化は壊れたライブラリ版の**回避**であり、潜在欠陥(依存物の浮動・動的リンク)と影響拡大要因(毎実行 migration)は残っている。

## 恒久対策(採用決定と実施計画)

担当は個人ではなくロールで割り当て、個人へのアサインは各追跡 issue 側で行う(最終承認: チーム)。

| # | 対策 | 対象層 | 決定 | 主担当(ロール) | 期限案 | 追跡 | 完了条件 |
|---|---|---|---|---|---|---|---|
| 1 | 成功途絶の監視 | 検知 | **採用** | infra 監視担当 | 2026-08-05 | [infra#5692](https://github.com/GiganticMinecraft/seichi_infra/issues/5692) | `kube_cronjob_status_last_successful_time` ベースの staleness アラート(または統計データ鮮度の直接監視)を追加し、失敗・復旧・時系列欠落・CronJob suspend 時の各ケースでテスト完了 |
| 2 | ビルド入力の固定と回帰テスト | 潜在欠陥 | **採用**(新規) | アプリ CI 担当 | 2026-08-09 | [conifers#200](https://github.com/GiganticMinecraft/seichi-timed-stats-conifers/issues/200) | (a) base イメージを digest で固定(更新は Renovate 追従)、(b) `cargo install --locked` の強制(diesel_cli は #197 で対応済み)、(c) migration イメージのビルド/配備を該当パス変更時のみに限定(migration SQL・Dockerfile・Cargo.lock・workflow・base digest 更新設定を含む)、(d) **本番相当 MariaDB 11.8 に対し migration を 2 回実行し 2 回目が no-op であることを CI で検証**(今回の故障機構を直接検出する回帰テスト)、(e) ビルド時依存一覧・イメージ digest・SBOM の保存。**注: APT パッケージが残る期間は完全な再現可能ビルドにはならず、回帰テストで危険な組合せを検出する設計** |
| 3 | migration の純 Rust 化 | 潜在欠陥 | **採用** | conifers 担当 | 2026-08-16 | [conifers#201](https://github.com/GiganticMinecraft/seichi-timed-stats-conifers/issues/201) | diesel_cli をやめ、diesel-async **0.9.2** の `AsyncMigrationHarness`(`migrations` feature、diesel_migrations ~2.3)+ `embed_migrations!` の専用バイナリに置換。C クライアント非依存を SBOM または依存木で確認。**ガード(下記 #5)の採否と理由を記録**。制約: multithreaded Tokio runtime 必須・`select!`/`join!` 内不可(その場合 `spawn_blocking`)。diesel-async 0.9.0→0.9.2 bump 要 |
| 4 | migration のリリース単位 Job 化 + DB ユーザー分離 | 影響拡大要因 | **採用** | conifers + infra 担当(ユーザー分離は DB + infra 担当) | 設計 2026-08-10・実装 2026-08-23 | [infra#5693](https://github.com/GiganticMinecraft/seichi_infra/issues/5693) | 5 分ごとの init 実行を廃止しリリース時 1 回の専用 Job に分離。**注: Job 化だけでは DDL 権限は消えない**(現在 migration と ingestor は同一 credentials)。migration 用ユーザー (DDL) と ingestor 用ユーザー (DML 限定) を分離し、**ingestor ユーザーに DDL 権限がないことを実測で確認**。要設計: migration 完了→新 ingestor 配備の順序保証、旧版互換、migration 失敗時に旧 ingest が継続すること |
| 5 | ガードの追加 | 故障機構の検知 | 案 3 の実装時に採否を判断(判断期限 = 案 3 の期限 2026-08-16、採否と理由は案 3 の完了条件に含む) | conifers 担当 | — | (案 3 に含む) | 採用する場合: version 非空・期待形式(`^\d{14}$`)・埋め込み migration 集合と適用済み集合の関係の妥当性を検査。可能なら通常の取得経路と独立した方法で読む(同じドライバ・同じ経路でのガードは共通原因故障になる)。単純な「既存テーブルあり × 全未適用」判定は正当なベースライン導入でも成立するため不採用 |
| 6 | mysql-bundled | 潜在欠陥 | **不採用**(案 3 が成立するため。#5102 で解消報告はあり) | — | — | — | — |
| 7 | libmariadb の apt pin | — | **不採用**(snapshot.debian.org 依存・セキュリティ更新停止) | — | — | — | — |

ポストモーテム完了タスク(恒久対策とは別に追跡):

- 利用者影響の調査: [infra#5694](https://github.com/GiganticMinecraft/seichi_infra/issues/5694)(表示側アプリ担当、期限案 2026-08-07)
- 通知から調査開始まで 6 時間 40 分の空白の経緯記録: [infra#5695](https://github.com/GiganticMinecraft/seichi_infra/issues/5695)(当日対応者=調査オーナー)

別件(独立 issue で追跡):

- **cosign 署名の欠落**: [seichi_infra#5690](https://github.com/GiganticMinecraft/seichi_infra/issues/5690) に切り出し済み。Kyverno Enforce 化のブロッカー

## 付録 A: ローカル対照実験の再現手順

環境: macOS (Apple Silicon) + apple/container CLI。**アーキテクチャは arm64 であり本番 (amd64) と異なる**(bookworm ビルドが本番と同一の症状を示したため、少なくともこの症状はアーキ非依存で再現する)。

**再現性の制約**: 下記の base イメージ digest を使っても、ビルド中の `apt-get update` は実行時点の Debian リポジトリを参照するため、**APT 由来の依存(libmariadb 等)は base digest だけでは再現できない**。実験成果物である `probe-diesel:{bookworm,trixie}` の完成イメージ digest は保存しないまま実験後に削除した(本質変数である libmariadb のパッケージ版数は下記抜粋に記録済み)。将来厳密に再現する場合は snapshot.debian.org でリポジトリとパッケージ版数を固定すること。

実験時に解決された base / DB イメージの digest(いずれも index digest、arm64 で実行):

| イメージ | digest (index) |
|---|---|
| `mariadb:11.8` | `sha256:efb4959ef2c835cd735dbc388eb9ad6aab0c78dd64febcd51bc17481111890c4` |
| `rust:1.97.1-slim-bookworm` | `sha256:99e09cb2284e2ddbb73a995deee3e91783fd04d177602ccf6eab326d778ee777` |
| `rust:1.97.1-slim-trixie` | `sha256:5c6f46a6e4472ab1ca7ba7d494e6677f2f219ebc02f32025d3986f057635ec9c` |

```bash
# 1. MariaDB 11.8 (本番は 11.8.8) を起動しデータ投入
container run -d --name probe-mariadb -e MARIADB_ROOT_PASSWORD=probe -e MARIADB_DATABASE=probe mariadb:11.8
container exec probe-mariadb mariadb -u root -pprobe probe -e "
  CREATE TABLE IF NOT EXISTS __diesel_schema_migrations (
    version varchar(50) NOT NULL,
    run_on timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (version)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
  INSERT IGNORE INTO __diesel_schema_migrations VALUES ('20230524025310', '2025-04-26 14:40:01');"

# 2. 動的リンクの diesel_cli を base 違いで 2 つビルド (アーキテクチャを明示)
container build --arch arm64 -t probe-diesel:trixie   --build-arg BASE=trixie   .
container build --arch arm64 -t probe-diesel:bookworm --build-arg BASE=bookworm .

# 3. 同一 DB に対して実行 (IP は container inspect で取得)
container run --rm -e DATABASE_URL='mysql://root:probe@<mariadb-ip>:3306/probe' probe-diesel:trixie
container run --rm -e DATABASE_URL='mysql://root:probe@<mariadb-ip>:3306/probe' probe-diesel:bookworm
```

Dockerfile:

```dockerfile
ARG BASE=bookworm
FROM rust:1.97.1-slim-${BASE}
RUN apt-get update && \
    apt-get install -y default-libmysqlclient-dev && \
    rm -rf /var/lib/apt/lists/* && \
    cargo install diesel_cli --version 2.3.11 --locked --no-default-features --features mysql
WORKDIR /probe
RUN mkdir -p migrations/20230524025310_create_initial_tables && \
    echo 'select 1;' > migrations/20230524025310_create_initial_tables/up.sql && \
    echo 'select 1;' > migrations/20230524025310_create_initial_tables/down.sql
CMD ["bash", "-c", "dpkg -l | grep -E 'libmariadb3|libmysqlclient' | awk '{print $2, $3}'; diesel migration list --database-url=$DATABASE_URL; echo EXIT=$?"]
```

結果(関連部分の抜粋。完全な生ログはセッション記録のみで、別ファイルとしては未保存):

```
# trixie
libmariadb3:arm64 1:11.8.6-0+deb13u1
Migrations:
  [X] 20230524025310_create_initial_tables
EXIT=0

# bookworm
libmariadb3:arm64 1:10.11.18-0+deb12u1
Migrations:
  [ ] 20230524025310_create_initial_tables
EXIT=0
```

## 付録 B: 本番クラスタでの観測

```bash
# 新イメージ (sha-8cf3333) のデバッグ Pod (CronJob と同一 env・同一 DB ユーザー):
$ diesel --version
diesel 2.3.11
$ diesel migration list --database-url=...
Migrations:
  [ ] 20230524025310_create_initial_tables   # ← 未適用判定

# 旧イメージ (sha-9cb78a5):
$ diesel --version
diesel 2.1.0

# dpkg (新 sha-8cf3333 は bookworm 時点):
旧: libmariadb3 1:10.11.3-1        (2023 年の bookworm)
新: libmariadb3 1:10.11.18-0+deb12u1

# DB 側 (mariadb-0 で root 実行):
SELECT version, HEX(version), LENGTH(version) FROM __diesel_schema_migrations;
-- 20230524025310 | 3230323330353234303235333130 | 14   (純 ASCII、不可視文字なし)
SHOW CREATE TABLE __diesel_schema_migrations;  -- varchar(50), utf8mb4_general_ci, InnoDB
SHOW GRANTS FOR 'seichi-timed-stats-conifers'@'%';
-- GRANT ALL PRIVILEGES ON `seichi-timed-stats-conifers`.* TO ...

# サーバー: mariadb 11.8.8 (x86_64, debian-linux-gnu)
```

## 付録 C: 横展開の確認

- `*-database-migration` イメージの使用箇所はクラスタ内で conifers のみ(manifests 全 grep)
- 他の initContainer は全て mcserver 系 (Java) で libmysqlclient 非依存
- conifers ingestor / 他 Rust サービスの DB 接続は mysql_async 系(純 Rust)を確認した範囲では使用
- 未実施: 全 Rust サービスのイメージに対する `ldd`/dpkg 棚卸し(動的リンク libmysqlclient の網羅確認)
