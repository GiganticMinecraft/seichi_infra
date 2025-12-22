# Kubernetesクラスターバージョンアップ

## 概要

kubeadmを使用したKubernetesクラスターのバージョンアップ手順。

## 前提条件

- コントロールプレーンノードへのSSHアクセス
- メンテナンスウィンドウの確保
- 現在のバージョンから1マイナーバージョンずつアップグレード

## 現在の構成

- 3 Control Plane nodes (cp-1, cp-2, cp-3)
- 3 Worker nodes (wk-1, wk-2, wk-3)
- CNI: Cilium

## 手順

### 1. 事前確認

```bash
# 現在のバージョン確認
kubectl get nodes -o wide
kubeadm version
```

### 2. コントロールプレーンのアップグレード（cp-1から）

```bash
# kubeadmのアップグレード
sudo apt update
sudo apt-cache madison kubeadm
sudo apt-get install -y kubeadm=<version>

# アップグレードプラン確認
sudo kubeadm upgrade plan

# アップグレード実行
sudo kubeadm upgrade apply v<version>

# kubelet, kubectlのアップグレード
sudo apt-get install -y kubelet=<version> kubectl=<version>
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### 3. 残りのコントロールプレーン（cp-2, cp-3）

```bash
sudo kubeadm upgrade node
sudo apt-get install -y kubelet=<version> kubectl=<version>
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### 4. ワーカーノードのアップグレード

```bash
# ノードをdrainする
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# ノード上で実行
sudo apt-get install -y kubeadm=<version>
sudo kubeadm upgrade node
sudo apt-get install -y kubelet=<version> kubectl=<version>
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# uncordon
kubectl uncordon <node-name>
```

### 5. 動作確認

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

## ロールバック手順

TODO: ロールバック手順を記載

## 関連リンク

- [Kubernetes公式アップグレードドキュメント](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [クラスタ構築手順](../guides/cluster-setup.md)
