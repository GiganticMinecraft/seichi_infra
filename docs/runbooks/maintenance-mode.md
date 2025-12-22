# Minecraftサーバーメンテナンスモード

## 概要

整地鯖のMinecraftサーバー群のメンテナンスモード操作手順。
トラフィックを遮断しつつ、Pod自体は起動したままにできる。

## 仕組み

- 各MinecraftサーバーのreadinessProbeが`maintenance-mode` ConfigMapを確認
- `enabled: "true"`の場合、readinessProbeが失敗
- 90秒後にServiceエンドポイントから除外される
- Pod再起動不要、ConfigMap変更後5秒以内に反映開始

## 手順

### メンテナンスモードの有効化

1. `seichi-onp-k8s/manifests/seichi-kubernetes/apps/seichi-minecraft/maintenance-mode/configmap.yaml`を編集

2. `enabled`を`"true"`に変更
   ```yaml
   data:
     enabled: "true"
   ```

3. コミット＆プッシュ

4. ArgoCDが自動反映（数分以内）

### メンテナンスモードの無効化

1. 同ファイルで`enabled: "false"`に変更

2. コミット＆プッシュ

## 注意事項

- Pod自体は起動し続けるため、リソースは解放されない
- 完全停止が必要な場合はArgo Workflowsを使用

## 関連リンク

- [DEPLOYMENT.md](https://github.com/GiganticMinecraft/seichi_infra/blob/main/DEPLOYMENT.md#minecraftサーバーのメンテナンスモード)
