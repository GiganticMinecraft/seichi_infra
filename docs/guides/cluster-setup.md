# Kubernetesクラスタ構築手順

## 概要

オンプレミス環境へのKubernetesクラスタ構築手順。

詳細は [cluster-boot-up/README.md](https://github.com/GiganticMinecraft/seichi_infra/blob/main/seichi-onp-k8s/cluster-boot-up/README.md) を参照。

## 環境

- Proxmox Virtual Environment 9.1.2
- Ubuntu 24.04 LTS（cloudinit）
- kubeadm v1.34.2
- CNI: Cilium
- 構成: 3 Control Plane + 3 Worker nodes

## ネットワーク構成

| ネットワーク | CIDR |
|-------------|------|
| Service Network | 192.168.0.0/20 |
| Storage Network | 192.168.16.0/22 |
| Pod Network | 10.96.128.0/18 |
| Service Network (k8s) | 10.96.64.0/18 |
| LoadBalancer VIP | 10.96.0.0/22 |

## クラスタ作成フロー

1. Proxmoxホスト上でVM作成スクリプト実行
2. ローカルマシンからSSH接続設定
3. cp-1でクラスタ初期化確認
4. cloudflaredリソースのデプロイ
5. Terraform Cloud設定
6. 初回terraform apply
7. cloudinitユーザーパスワード変更

## クラスタ削除

詳細は [cluster-boot-up/README.md#クラスタの削除](https://github.com/GiganticMinecraft/seichi_infra/blob/main/seichi-onp-k8s/cluster-boot-up/README.md#クラスタの削除) を参照。
