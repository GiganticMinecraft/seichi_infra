# Kubernetesクラスター内証明書の更新

## 概要

kubeadmで管理されるKubernetesクラスター内証明書の更新手順。
証明書は1年で期限切れになるため、定期的な更新が必要。

## 前提条件

- コントロールプレーンノードへのSSHアクセス

## 手順

### 1. 証明書の有効期限確認

```bash
sudo kubeadm certs check-expiration
```

### 2. 証明書の更新（各コントロールプレーンノードで実行）

```bash
# 全証明書を更新
sudo kubeadm certs renew all

# kubeletを再起動
sudo systemctl restart kubelet
```

### 3. kubeconfigの更新

```bash
# 管理者用kubeconfigを再生成
sudo kubeadm kubeconfig user --client-name=admin --org=system:masters > admin.conf
```

### 4. 動作確認

```bash
kubectl get nodes
sudo kubeadm certs check-expiration
```

## 自動更新について

kubeletは自動的にクライアント証明書を更新しますが、APIサーバー等の証明書は手動更新が必要です。

## 関連リンク

- [Kubernetes証明書管理](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
