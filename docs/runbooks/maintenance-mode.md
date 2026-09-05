# Minecraftサーバーメンテナンスモード

## 概要

整地鯖のMinecraftサーバー群のメンテナンスモード操作手順。
全サーバー一括、または特定サーバーのみを対象に、トラフィックを遮断しつつPod自体は起動したままにできる。

## 仕組み

- 各MinecraftサーバーのreadinessProbeが、5秒ごとに`maintenance-mode` ConfigMapを確認
- `enabled: "true"`（全サーバー共通）または`enabled--{suffix}: "true"`（サーバー個別）の場合、readinessProbeが失敗し続ける
- `failureThreshold: 18` × `periodSeconds: 5` = 90秒後にServiceエンドポイントから除外され、トラフィックが遮断される
- Pod再起動不要、ConfigMap変更後5秒以内に反映開始
- GitOpsによる管理のため、変更履歴が全てGitに記録される

## 手順

### 全サーバーのメンテナンスモードを有効化

1. `seichi-onp-k8s/manifests/seichi-kubernetes/apps/seichi-minecraft/maintenance-mode/configmap.yaml`を編集し、`enabled`を`"true"`に変更:
   ```yaml
   data:
     enabled: "true"
   ```
2. コミット＆プッシュ
3. ArgoCDが自動反映（数分以内）。反映後、5秒以内に全サーバーのreadinessProbeが失敗し始め、90秒後に全トラフィックが遮断される

### 特定サーバーのみメンテナンスモードを有効化

1. 同ファイルを編集し、対象サーバーの`enabled--{suffix}`を`"true"`に変更（例: s1のみ）:
   ```yaml
   data:
     enabled--s1: "true"
   ```
   対応するsuffix: `s1` / `s2` / `s3` / `s5` / `s7` / `lobby` / `votelistener` / `kagawa` / `one-day-to-reset`
2. コミット＆プッシュ
3. ArgoCDが自動反映（数分以内）。反映後、対象サーバーのみreadinessProbeが失敗し始め、90秒後にトラフィックが遮断される

### メンテナンスモードの無効化

1. 同ファイルで変更したキーを`"false"`に戻す
2. コミット＆プッシュ
3. ArgoCDが反映後、5秒以内にreadinessProbeが成功し始め、即座にServiceエンドポイントに復帰する

## 注意事項

- Pod自体は起動し続けるため、リソースは解放されない
- 完全停止が必要な場合はArgo Workflowsを使用

## 関連リンク

- [DEPLOYMENT.md](https://github.com/GiganticMinecraft/seichi_infra/blob/main/DEPLOYMENT.md#minecraftサーバーのメンテナンスモード)
