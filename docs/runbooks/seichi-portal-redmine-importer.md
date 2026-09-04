# SeichiPortal への Redmine 移行手順

## 目的と前提

Redmine の issue、journal comment、issue relation を SeichiPortal のフォーム回答へ移行するための、
一回限りの data migration／import Kubernetes Job の運用手順。Importer は次の固定 image を使用する。

```text
ghcr.io/giganticminecraft/seichi-portal-redmine-importer:163de71799135a2445b99707cde02bf5621eea18@sha256:5406a8b58d56020bb6256711a73ca25a5bacb99fe8452ec3b557a50e5dede9cf
```

この Job は Redmine API から GET するだけで、Redmine へ書き込まない。Portal DB への保存は image 内の
backend の Domain / Usecase / Repository 経由で行い、backend HTTP API、Redis、RabbitMQ、Meilisearch には
接続しない。

SQL dump (`seichi-portal-pre-redmine-import-without-debug-users.sql`) 自体は、このリポジトリの Git、
ConfigMap、Secret、image のいずれにも保存しない。dump に含まれる importer 実行前の Portal 初期データは、
schema と `_sqlx_migrations` を除いた data-only migration として
`seichi-portal-redmine-importer/database-migration/001-pre-redmine-seed.sql` に反映している。この migration は
GitOps で一度だけ適用する ConfigMap と MariaDB client Job から構成し、完了後に directory ごと削除する。
schema と SQLx migration の管理は backend 側に任せる。バックアップと復元は、運用者が承認済みの DB 運用経路で
行う。

## Secret の事前準備

既存の seichi_infra は、sensitive な Terraform variable を GitHub Actions の Secret から渡し、
Terraform の `kubernetes_secret_v1` resource で Kubernetes Secret を作成している。この移行でも同じ方式を
使う。

1. この PR の Terraform plan が実行される前に、GitHub Actions の repository secret として
   `TF_VAR_SEICHI_PORTAL_REDMINE_IMPORTER__API_KEY` を out-of-band で登録する。値は GitHub の Secret 設定画面
   または標準入力を使う CLI から登録し、コマンドライン引数、シェル履歴、ログへ出さない。この Secret がない
   状態では、必須 Terraform variable に値が入らず plan が失敗する。
2. Secret 登録後、PR の `tf plan` が成功することを確認する。既存 workflow の
   `expose-all-tf-vars-to-github-env.sh` が Secret 名の `TF_VAR_` 以降を小文字化し、Terraform variable
   `seichi_portal_redmine_importer__api_key` へ渡す。
3. PR merge 後、既存の Terraform apply workflow が成功することを確認する。workflow は Secret の値を
   namespace `seichi-minecraft` の `seichi-portal-redmine-importer-credentials` Secret に
   `REDMINE_API_KEY` として保存する。
4. Kubernetes Secret の存在と `REDMINE_API_KEY` key の存在だけを確認する。Secret の値は表示しない。

API key と DB password の値は、Git、YAML、Job の args、ログ、README に書かない。移行完了後、Job と
NetworkPolicy を prune したことを確認してから、Terraform の Secret resource／variable を削除する cleanup
PR を作成し、その merge 後に GitHub Actions の repository secret も削除する。

## ArgoCD の実行 gate

`seichi-minecraft-seichi-portal-redmine-importer` は ApplicationSet が生成する Application である。root
kustomization には importer、data migration、plan、verify の全 resource を含めているが、初回 merge では
一回限りの Job／ConfigMap／CiliumNetworkPolicy のすべてに `argocd.argoproj.io/sync-options: Skip` が付いている
ため、live resource は作成されない。`plan`／`verify` もこの Application の同期対象であり、直接
`kubectl apply` して作成するものではない。以下に出てくる `kubectl` は、状態・ログ・削除確認の read-only 操作
だけに使う。

同期 wave は CiliumNetworkPolicy／ConfigMap が `-1`、data migration Job が `0`、plan Job が `1`、importer
Job が `2`、verify Job が `3` である。各 Job は Kubernetes API を呼び出さず、`automountServiceAccountToken: false`
のため、Role／RoleBinding／専用 ServiceAccount は定義しない。DB と Redmine への接続権限は Secret と
CiliumNetworkPolicy で与える。

DB 復元後、まず data migration だけを有効化する Git change を作成して merge する。具体的には
`database-migration/kustomization.yaml` の ConfigMap、`database-migration/job.yaml` の Job、
`database-migration/network-policy.yaml` の CiliumNetworkPolicy から `Skip` annotation を削除し、base の
importer Job／NetworkPolicy と plan／verify overlay は `Skip` のままにする。この Git change の merge と
ArgoCD の自動同期だけで resource を作成する。

data migration が完了したら、`plan/kustomization.yaml` の Job patch に Job の `Skip` を削除する JSON patch を
追加し、同じ overlay に plan 用 CiliumNetworkPolicy の `Skip` を削除する patch を追加する Git change を merge
する。これにより wave `1` の plan Job と wave `-1` の plan 用 NetworkPolicy が ArgoCD によって作成される。
plan 完了後は、base の importer Job／NetworkPolicy の `Skip` だけを削除する別の enable change を merge する。
base Job の `args` は常に `["import"]` のままにする。import 完了後は同じ方法で
`verify/kustomization.yaml` の Job／NetworkPolicy の `Skip` を削除する Git change を merge する。
各段階で、後続の Job を有効化する前に直前の Job の Complete とログを確認する。

ArgoCD が Job を作成した後は、desired manifest を変更しない限り、完了した Job が自動的に再実行されることは
ない。実行済みの Job／NetworkPolicy を途中で直接削除せず、最後に one-off directory を Git から削除して
ApplicationSet と ArgoCD の prune に任せる。

移行完了後は one-off directory 全体を Git から削除する cleanup change を merge する。ApplicationSet が
generated Application を削除し、ArgoCD の Application finalizer による prune で live resource も削除される。
base resource を先に手動削除して再作成を誘発しない。

## 実行手順

### 1. 本番 DB の現行バックアップを取得する

現行の Portal DB を復元できるバックアップを取得し、バックアップの取得時刻と保存先を記録する。既存の
MariaDB backup workflow を使う場合も、workflow の成功だけでなく、復元に使う backup object が存在することを
確認する。

### 2. Portal backend の書き込みを停止する

Portal backend を maintenance 状態にする既存の運用手順を使い、書き込みリクエストが届かないことを確認
する。Portal 側に maintenance 機能がない場合は、運用者が ArgoCD の self-heal と競合しないよう backend の
Application を一時的に同期停止したうえで Deployment を停止し、backend Pod が残っていないことを確認する。

この Job 自体から backend Deployment を scale down、再起動、変更してはいけない。frontend や外部の書き込み
経路も停止または遮断し、移行と DB 復元が終わるまで維持する。

### 3. test user を除外した Portal DB backup を復元する

手順 1 のバックアップ、またはそれを復元元とする承認済みの DB restore 手順を使う。復元元の backup から
次の test user と、それらに紐づくデバッグ用 BAN を除外する。

- `test_user`
- `test_std_user`

除外処理と SQL dump は運用環境の外部作業領域だけで行い、Git、ConfigMap、Secret、image に入れない。

### 4. DB の復元完了を確認する

MariaDB の restore resource、restore Job、対象 database の接続状態をそれぞれ確認する。restore が完了する
前に次の手順へ進まない。Importer が使用する接続先は `mariadb:3306`、database/user は
`seichi-portal` である。

### 5. data migration を適用し、必要なフォーム、質問、ラベルを確認する

まず、schema migration が完了し、`seichi-portal` DB user が対象 database に接続できることを確認する。次に
data migration だけを有効化する change を作成して merge し、ApplicationSet が生成した Application の sync と
次の Job の完了を待つ。

```bash
kubectl -n seichi-minecraft wait \
  --for=condition=complete \
  job/seichi-portal-pre-redmine-migration \
  --timeout=1h
kubectl -n seichi-minecraft logs job/seichi-portal-pre-redmine-migration
```

Job のログに SQL 実行エラーがなく、`seichi-portal-pre-redmine-migration` が `Complete` になっていることを
確認する。この Job は dump 全体を restore するものではなく、Git 管理の data-only migration を既存 schema へ
適用するものである。今回の migration が投入する行数の確認目安は users 1、forms 18、questions 46、choices 47、
labels 18、form_discord_webhooks 18、global_discord_webhook_settings 1 である。

data migration 完了後、Importer image 内の `/etc/seichi-portal/redmine-import.json` と Portal DB の値が一致する
ことを確認する。少なくとも tracker に対応するフォーム、各 form の全 question、choice、label が存在し、必須
question に mapping があることを確認する。特に次を確認する。

- アイデア投稿フォーム
- 公共建築フォーム
- 修繕依頼フォーム
- 不要保護報告フォーム
- `移行元トラッカー: ...` の answer label と、status 用 label
- 公共建築の終了条件、修繕依頼の server／world／coordinate／修繕内容、不要保護報告の対象 ID／場所／理由を
  保存する質問

件数確認やフォーム確認の SQL は、承認済み DB tooling から既存の `seichi-portal` DB user で read-only に
実行する。password は対話入力または tooling の Secret 参照を使い、コマンドへ値を埋め込まない。DB root password
は importer の接続にも確認作業にも使わない。

### 6. 同じ image で plan を実行する

data migration Job が成功し、フォーム、question、choice、label の確認が終わるまで plan overlay と base
importer Job は `Skip` のままにする。`plan` overlay は root kustomization から常に render されているため、
実行時には `plan/kustomization.yaml` の Job patch と CiliumNetworkPolicy patch に、それぞれ次の JSON patch を
追加する Git change を作成して merge する。

```yaml
- op: remove
  path: /metadata/annotations/argocd.argoproj.io~1sync-options
```

この change の merge と ArgoCD の自動同期によってだけ、同じ image、Secret、resources、securityContext、egress
policy を使う `seichi-portal-redmine-importer-plan` Job と NetworkPolicy が作成される。
`kubectl apply -k` は実行しない。作成後の状態とログは次の read-only コマンド、または ArgoCD の画面で確認する。

```bash
kubectl -n seichi-minecraft wait \
  --for=condition=complete \
  job/seichi-portal-redmine-importer-plan \
  --timeout=12h
kubectl -n seichi-minecraft logs job/seichi-portal-redmine-importer-plan
```

`plan` は Redmine の対象 issue と詳細、フォーム、question、status、label、既存回答を照合する。ログに
`report: 0 error(s), 0 warning(s)` が出ることを確認し、エラーがあれば import を有効化しない。警告は内容を
確認してから進める。

plan の出力で、アイデア投稿が専用フォームへ分類されること、公共建築・修繕依頼・不要保護報告が専用フォーム
と custom field question へ割り当てられることを確認する。Portal 側の公開範囲は、現在の image の設定では
アイデア投稿だけが `PUBLIC`、それ以外が `PRIVATE` になる。これは後述の import 後の DB 確認でも検証する。

plan が成功し、DB restore と data migration、フォーム確認にも問題がなければ、plan Job と plan NetworkPolicy は
そのまま残す。base importer Job と importer NetworkPolicy の `Skip` annotation だけを削除する有効化 PR を
merge し、ArgoCD Application が importer Job を作成するのを待つ。data migration と plan の resource は既に
完了済みなので、再度作成・実行しない。

### 7. 問題がなければ import Job を実行する

有効化 PR の merge 後、ApplicationSet が生成した
`seichi-minecraft-seichi-portal-redmine-importer` の sync を待つ。data migration Job が Complete の状態で
残っていることと、importer Job が sync wave `2` で作成されたことを確認する。Job を手動で別名作成したり、base
Job の args を書き換えたりしない。

### 8. Job のログと完了状態を確認する

`backoffLimit: 0` のため自動再実行は発生しない。Job の完了と Pod の終了コードを確認し、ログを保存する。

```bash
kubectl -n seichi-minecraft get job seichi-portal-redmine-importer
kubectl -n seichi-minecraft wait \
  --for=condition=complete \
  job/seichi-portal-redmine-importer \
  --timeout=12h
kubectl -n seichi-minecraft logs job/seichi-portal-redmine-importer
```

`IMPORT ... result=Imported` または再実行時の `AlreadyImported`、および
`IMPORT answer_relations inserted=... already_exists=...` を確認する。失敗時は Job を削除して再作成せず、
ログと DB の状態を保存して復元元・エラー原因を調査する。

### 9. 同じ image で verify を実行する

import Job が完了し、ログを確認した後、`verify/kustomization.yaml` の Job patch と
CiliumNetworkPolicy patch に、それぞれ Job／NetworkPolicy の `Skip` を削除する次の JSON patch を追加する Git
change を作成して merge する。

```yaml
- op: remove
  path: /metadata/annotations/argocd.argoproj.io~1sync-options
```

ArgoCD の自動同期によって `seichi-portal-redmine-importer-verify` Job が作成される。verify でも DB への
read-only 照合と Redmine API の GET が行われる。`kubectl apply -k` や `kubectl delete -k` は実行せず、作成後の
状態とログだけを read-only に確認する。

```bash
kubectl -n seichi-minecraft wait \
  --for=condition=complete \
  job/seichi-portal-redmine-importer-verify \
  --timeout=12h
kubectl -n seichi-minecraft logs job/seichi-portal-redmine-importer-verify
```

全対象 issue の `VERIFY ... result=AlreadyImported` を確認する。`ImportRequired`、エラー、または件数の
不一致がある場合は通常運用へ戻さず、DB とログを調査する。

### 10. 件数と公開範囲を確認する

次の SQL を、既存の `seichi-portal` DB user で read-only に実行する。テーブル名は importer の保存先に
合わせている。復元 DB に移行済みデータが既にある場合は、移行前の件数との差分も記録する。

```sql
SELECT COUNT(*) AS imported_issues
FROM redmine_imported_answer_references;

SELECT COUNT(*) AS imported_journal_comments
FROM redmine_imported_comments;

SELECT COUNT(*) AS imported_answer_relations
FROM answer_relations AS relation
JOIN redmine_imported_answer_references AS first_issue
  ON first_issue.answer_id = relation.first_answer_id
JOIN redmine_imported_answer_references AS second_issue
  ON second_issue.answer_id = relation.second_answer_id;

SELECT answer.publication, COUNT(*) AS count
FROM answers AS answer
JOIN redmine_imported_answer_references AS imported
  ON imported.answer_id = answer.id
GROUP BY answer.publication
ORDER BY answer.publication;

SELECT answer.form_id, form.title, answer.publication, COUNT(*) AS count
FROM answers AS answer
JOIN redmine_imported_answer_references AS imported
  ON imported.answer_id = answer.id
JOIN form_meta_data AS form
  ON form.id = answer.form_id
GROUP BY answer.form_id, form.title, answer.publication
ORDER BY form.title, answer.publication;
```

今回のローカル確認値は目安として次のとおり。Redmine 側の issue、journal、relation が更新されていれば値は
変わり得るため、Job や SQL の期待値として hard-code しない。

- 移行対象 issue: 約 12,491
- Redmine journal comment: 約 14,530
- answer relation: 約 2,186
- verify: 全件 `AlreadyImported`

件数だけでなく、アイデア投稿だけが `PUBLIC`、その他が `PRIVATE` であることを確認する。フォーム別集計では、
公共建築・修繕依頼・不要保護報告の回答がそれぞれ専用フォームに入り、対応する custom field が専用 question
へ移っていることも確認する。

### 11. Job と一時 NetworkPolicy の manifest を削除する

plan／verify を含むすべての Job のログと DB 確認が終わった後、次の one-off directory 全体を Git から削除する
cleanup change を作成して merge する。Job や NetworkPolicy を先に `kubectl delete` してはいけない。

```text
seichi-onp-k8s/manifests/seichi-kubernetes/apps/seichi-minecraft/seichi-portal-redmine-importer/
```

cleanup change を merge する前に、生成された Application の `metadata.finalizers` に
`resources-finalizer.argocd.argoproj.io` が付いていることと、ApplicationSet の
`preserveResourcesOnDeletion` が有効になっていないことを確認する。これらを確認できない場合は directory を
削除せず、ArgoCD の Application 削除時に resource prune が行われる状態を先に復旧する。

```bash
kubectl -n argocd get application seichi-minecraft-seichi-portal-redmine-importer \
  -o jsonpath='{.metadata.finalizers}{"\n"}'
kubectl -n argocd get applicationset seichi-minecraft-apps \
  -o jsonpath='{.spec.preserveResourcesOnDeletion}{"\n"}'
```

ApplicationSet が `seichi-portal-redmine-importer` Application を削除し、ArgoCD の Application finalizer による
prune が完了して、次の Job、ConfigMap、CiliumNetworkPolicy がすべて存在しなくなったことを確認する。

- `seichi-portal-redmine-importer` Job
- `seichi-portal-redmine-importer-plan` Job
- `seichi-portal-redmine-importer-verify` Job
- `seichi-portal-pre-redmine-migration` Job
- `seichi-portal-pre-redmine-migration-sql` ConfigMap
- `allow--from-seichi-portal-redmine-importer--to-import-dependencies` CiliumNetworkPolicy
- `allow--from-seichi-portal-redmine-importer--to-import-dependencies-plan` CiliumNetworkPolicy
- `allow--from-seichi-portal-redmine-importer--to-import-dependencies-verify` CiliumNetworkPolicy
- `allow--from-seichi-portal-pre-redmine-migration--to-mariadb` CiliumNetworkPolicy

確認例:

```bash
kubectl -n seichi-minecraft get job seichi-portal-redmine-importer
kubectl -n seichi-minecraft get job seichi-portal-redmine-importer-plan
kubectl -n seichi-minecraft get job seichi-portal-redmine-importer-verify
kubectl -n seichi-minecraft get job seichi-portal-pre-redmine-migration
kubectl -n seichi-minecraft get configmap seichi-portal-pre-redmine-migration-sql
kubectl -n seichi-minecraft get ciliumnetworkpolicy \
  allow--from-seichi-portal-redmine-importer--to-import-dependencies
kubectl -n seichi-minecraft get ciliumnetworkpolicy \
  allow--from-seichi-portal-redmine-importer--to-import-dependencies-plan
kubectl -n seichi-minecraft get ciliumnetworkpolicy \
  allow--from-seichi-portal-redmine-importer--to-import-dependencies-verify
kubectl -n seichi-minecraft get ciliumnetworkpolicy \
  allow--from-seichi-portal-pre-redmine-migration--to-mariadb
```

`NotFound` になったことを確認してから、Terraform の importer Secret resource と variable、GitHub Actions
repository secret の削除も cleanup PR として行う。Job のログと DB 確認が終わるまで、base resource を
`kubectl delete` してはいけない。

### 12. backend の通常運用を再開する

Portal backend の書き込み停止または maintenance 状態を解除し、Deployment を通常の replica 数へ戻す。backend
Pod が Ready になり、Portal から通常の read/write ができることを確認する。

### 13. backend 側の Redmine importer PR を revert する

移行結果と通常運用を確認した後、`seichi-portal-backend` repository の Redmine importer merge PR（merge
commit `163de71799135a2445b99707cde02bf5621eea18`、PR #1383）を revert する。revert は backend repository
側で別途行い、この repository の backend source は変更しない。
