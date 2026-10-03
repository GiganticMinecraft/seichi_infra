# Minecraftサーバーメンテナンスモード

## 概要

整地鯖のMinecraftサーバー群のメンテナンスモード操作手順。
全サーバー一括、または特定サーバーのみを対象に、トラフィックを遮断しつつPod自体は起動したままにできる。

## 仕組み

- 各MinecraftサーバーのreadinessProbeが、5秒ごとに`maintenance-mode` ConfigMapを確認
- `enabled: "true"`（全サーバー共通）または`enabled--{suffix}: "true"`（サーバー個別）の場合、readinessProbeが失敗し続ける
- `failureThreshold: 18` × `periodSeconds: 5` = 90秒後にServiceエンドポイントから除外され、トラフィックが遮断される
- Pod再起動は不要。ただしConfigMapの変更がPod内のファイルに届くまでkubeletの同期待ちがあり、通常は数十秒〜1分強かかる（5秒はreadinessProbeの実行間隔であって、反映までの時間ではない）
- GitOpsによる管理のため、変更履歴が全てGitに記録される
- AppProjectのSync Windowにより自動Syncが走るのは毎日7:00〜8:00（JST）だけなので、それ以外の時間はArgo CDで手動Syncしないと反映されない

## 手順

### 全サーバーのメンテナンスモードを有効化

1. `seichi-onp-k8s/manifests/seichi-kubernetes/apps/seichi-minecraft/maintenance-mode/configmap.yaml`を編集し、`enabled`を`"true"`に変更:
   ```yaml
   data:
     enabled: "true"
   ```
2. コミット＆プッシュ
3. Argo CD UIでApplication `seichi-minecraft-maintenance-mode` の差分を確認し、手動でSync
4. Sync後、ConfigMapの変更がPodに届くと（通常1分強以内）全サーバーのreadinessProbeが失敗し始め、その90秒後に全トラフィックが遮断されたことを確認

### 特定サーバーのみメンテナンスモードを有効化

1. 同ファイルを編集し、対象サーバーの`enabled--{suffix}`を`"true"`に変更（例: s1のみ）:
   ```yaml
   data:
     enabled--s1: "true"
   ```
   対応するsuffix: `s1` / `s2` / `s3` / `s5` / `s7` / `lobby` / `votelistener` / `kagawa` / `one-day-to-reset`
2. コミット＆プッシュ
3. Argo CD UIでApplication `seichi-minecraft-maintenance-mode` の差分を確認し、手動でSync
4. Sync後、ConfigMapの変更がPodに届くと（通常1分強以内）対象サーバーだけreadinessProbeが失敗し始め、その90秒後にトラフィックが遮断されたことを確認

### メンテナンスモードの無効化

1. 同ファイルで変更したキーを`"false"`に戻す
2. コミット＆プッシュ
3. Argo CD UIでApplication `seichi-minecraft-maintenance-mode` を手動でSync
4. Sync後、ConfigMapの変更がPodに届くと（通常1分強以内）、readinessProbeが成功してServiceエンドポイントに復帰したことを確認

## 注意事項

- Pod自体は起動し続けるため、リソースは解放されない
- 完全停止が必要な場合はArgo Workflowsを使用
- メンテナンスモード中のサーバーは、夜間のmcserverバックアップ（サーバーを0台にしてから取得する処理）がスキップされる。スキップは失敗扱いにならないので、失敗通知も出ない
- 全サーバー共通の `enabled` が `"true"` の間は、MariaDBのバックアップも止まる。こちらは従来どおり失敗として通知される

## 関連リンク

- [DEPLOYMENT.md](https://github.com/GiganticMinecraft/seichi_infra/blob/main/DEPLOYMENT.md#minecraftサーバーのメンテナンスモード)
