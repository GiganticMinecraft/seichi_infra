# Thanos Querier / Store Gateway / Compactor

kube-prometheus-stack の Thanos sidecar が Garage S3 にアップロードしている長期メトリクスを、
Grafana から Prometheus 直結ではなく Thanos Querier 経由で透過的に読めるようにする。

## 構成

`main.jsonnet` が [thanos-io/kube-thanos](https://github.com/thanos-io/kube-thanos) の
公式 jsonnet ライブラリを `vendor/` 配下から import し、本クラスタ用のパラメータで render する。
ArgoCD は `directory.jsonnet` でこれを評価して manifest を生成する。

依存は `jsonnetfile.json` で宣言、`jsonnetfile.lock.json` で commit hash 固定。
Renovate の `jsonnet-bundler` manager (`config:recommended` で標準有効) が
新しい kube-thanos リリースを検出して PR を出す。

## ローカルでの作業

```bash
brew install jsonnet jsonnet-bundler
cd seichi-onp-k8s/manifests/seichi-kubernetes/apps/thanos

# 依存更新 (Renovate が自動 PR を出すので通常は不要)
jb update

# render を確認
jsonnet -J vendor main.jsonnet | jq '[.[] | {kind, name: .metadata.name}]'
```

## Grafana datasource を Querier に切替えるには

`prometheus-operator.yaml` の Grafana datasource `Prometheus` の `url` を
`http://prometheus-kube-prometheus-prometheus:9090` から
`http://thanos-query.monitoring.svc.cluster.local:9090` に変更すると、
ローカル直近 (sidecar) + Garage 上の長期 (Store Gateway) の両方が透過的に見える。

切替後は Prometheus の `retention` / `retentionSize` を縮める余地がある (現在 180d / 270GB)。
