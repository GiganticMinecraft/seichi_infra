# seichi-onp-k8s

オンプレミス上に整地鯖用のKubernetesクラスタをデプロイする為のスクリプト群です。
前提としている環境については、以下前提条件を参照してください。

## 前提条件

- Proxmox Virtual Environment 7.1-11
  - 3ノードクラスタ構成
  - AMDとIntelが混在しているので、アーキテクチャを跨いだLive Migrationは不可
- Synology NAS(DS1621+)
  - 共有ストレージとして利用
- Ubuntu 20.04 LTS (cloud-init image)
  - Kubernetes VMのベースとして使用
- Network Addressing(うんちゃま自宅鯖本番環境)
  - Service Network Segment (192.168.0.0/20)
  - Storage Network Segment (192.168.16.0/22)
  - Kubernetes
    - Internal
      - Pod Network (10.128.0.0/16)
      - Service Network (10.96.0.0/16)
    - External
      - Node IP
        - Service Network (192.168.8.0-192.168.8.127)
        - Storage Network (192.168.18.0-192.168.18.127)
      - API Endpoint (192.168.18.100)
      - LoadBalancer VIP (192.168.8.128-192.168.8.255)
- Kubernetes構成情報
  - kubeadm, kubectl, kubelet v1.24.0
  - Cillium (Container Network Interface)

## クラスタ操作

作成フロー完了後は`seichi-onp-k8s-cp-1`に公開鍵認証でSSHログイン後`kubectl`を利用したクラスタ操作が可能です。

ログイン可能な公開鍵は"クラスタ作成時"に[`seichi-onp-k8s-cp-1`のcloud-config(userdata)](./snippets/seichi-onp-k8s-cp-1-user.yaml)の`runcmd:`に定義されている公開鍵に基づいています。

クラスタの再作成を伴わずにログイン可能な公開鍵を追加する場合は、直接`~/.ssh/authorized_keys`に追記してください。合わせて、次回クラスタ作成時に反映されるように[`seichi-onp-k8s-cp-1`のcloud-config(userdata)](./snippets/seichi-onp-k8s-cp-1-user.yaml)への追記も行ってください。

ログイン可能な公開鍵を確認したら、以下の手順でログインが可能です：

- ローカル端末上で`~/.ssh/config`をセットアップ

```
Host <踏み台サーバーホスト名>
  HostName <踏み台サーバーホスト名>
  User <踏み台サーバーユーザー名>
  IdentityFile ~/.ssh/id_ed25519

Host seichi-onp-k8s-cp-1
  HostName 192.168.18.11
  User cloudinit
  IdentityFile ~/.ssh/id_ed25519
  ProxyCommand ssh -W %h:%p <踏み台サーバーホスト名>
```

- (Option)初回接続後クラスターが再作成された場合はknown_hosts登録削除が必要(VM作り直す度にホスト公開鍵が変わる為)

```sh
ssh-keygen -R 192.168.18.11
```

- 接続チェック

```sh
ssh seichi-onp-k8s-cp-1 "kubectl get node && kubectl get pod -A"
```

### クラスタのエンドポイントについて

踏み台より先(内部NW)でクラスターを操作する場合、各環境のHAProxyに持たせたVIP(API Endpoint)に接続することができますが、構成の都合上外部からも接続可能なエンドポイントが存在します。

FQDNについては公開しない前提ですが、クラスターへのアクセス権限がある場合は`seichi-systems` Namespace内の`external-k8s-endpoint`というSecretリソースを参照することでFQDNを取得可能です。

## 作成フロー

- 以下は本リポジトリのサクッと作ってサクッと壊す対象外なので別途用意しておく
  - ベアメタルなProxmox環境の構築
  - Snippetが配置可能な共有ストレージの構築
  - VM Diskが配置可能な共有ストレージの構築
  - Network周りの構築

- proxmoxのホストコンソール上で`deploy-vm.sh`を実行すると、各種VMが沸く

  `/bin/bash <(curl -s https://raw.githubusercontent.com/GiganticMinecraft/seichi_infra/deploy-k8s-on-premises/seichi-onp-k8s/cluster-boot-scripts/deploy-vm.sh)`

- proxmoxのホストコンソール上で以下コマンド実行。(AMDとIntelが混在しているので、アーキテクチャを跨いだLive Migrationは不可)

```sh
# migrate vm
qm migrate 1001 unchama-sv-prox01
qm migrate 1002 unchama-sv-prox02
qm migrate 1003 unchama-sv-prox04
qm migrate 1101 unchama-sv-prox01
qm migrate 1102 unchama-sv-prox02
qm migrate 1103 unchama-sv-prox04
```

- proxmoxのホストコンソール上で以下コマンド実行。ノードローカルにいるVMしか操作できない為、全てのノードで打って回る。

```sh
# start vm
## on unchama-sv-prox01
qm start 1001
qm start 1101
## on unchama-sv-prox02
qm start 1002
qm start 1102
## on unchama-sv-prox04
qm start 1003
qm start 1103
```

- ローカル端末上で`~/.ssh/config`をセットアップ

```
Host <踏み台サーバーホスト名>
  HostName <踏み台サーバーホスト名>
  User <踏み台サーバーユーザー名>
  IdentityFile ~/.ssh/id_ed25519

Host seichi-onp-k8s-cp-1
  HostName 192.168.18.11
  User cloudinit
  IdentityFile ~/.ssh/id_ed25519
  ProxyCommand ssh -W %h:%p <踏み台サーバーホスト名>

Host seichi-onp-k8s-cp-2
  HostName 192.168.18.12
  User cloudinit
  IdentityFile ~/.ssh/id_ed25519
  ProxyCommand ssh -W %h:%p <踏み台サーバーホスト名>

Host seichi-onp-k8s-cp-3
  HostName 192.168.18.13
  User cloudinit
  IdentityFile ~/.ssh/id_ed25519
  ProxyCommand ssh -W %h:%p <踏み台サーバーホスト名>

Host seichi-onp-k8s-wk-1
  HostName 192.168.18.21
  User cloudinit
  IdentityFile ~/.ssh/id_ed25519
  ProxyCommand ssh -W %h:%p <踏み台サーバーホスト名>

Host seichi-onp-k8s-wk-2
  HostName 192.168.18.22
  User cloudinit
  IdentityFile ~/.ssh/id_ed25519
  ProxyCommand ssh -W %h:%p <踏み台サーバーホスト名>

Host seichi-onp-k8s-wk-3
  HostName 192.168.18.23
  User cloudinit
  IdentityFile ~/.ssh/id_ed25519
  ProxyCommand ssh -W %h:%p <踏み台サーバーホスト名>
```

- ローカル端末上でコマンド実行

```sh
# known_hosts登録削除(VM作り直す度にホスト公開鍵が変わる為)
ssh-keygen -R 192.168.18.11
ssh-keygen -R 192.168.18.12
ssh-keygen -R 192.168.18.13
ssh-keygen -R 192.168.18.21
ssh-keygen -R 192.168.18.22
ssh-keygen -R 192.168.18.23

# 接続チェック(ホスト公開鍵の登録も兼ねる)
ssh seichi-onp-k8s-cp-1 "hostname"
ssh seichi-onp-k8s-cp-2 "hostname"
ssh seichi-onp-k8s-cp-3 "hostname"
ssh seichi-onp-k8s-wk-1 "hostname"
ssh seichi-onp-k8s-wk-2 "hostname"
ssh seichi-onp-k8s-wk-3 "hostname"

# 最初のコントロールプレーンのkubeadm initが終わっているかチェック
ssh seichi-onp-k8s-cp-1 "kubectl get node && kubectl get pod -A"

# cloudinitの実行ログチェック(トラブルシュート用)
ssh seichi-onp-k8s-cp-1 "sudo cat /var/log/cloud-init-output.log"
ssh seichi-onp-k8s-cp-2 "sudo cat /var/log/cloud-init-output.log"
ssh seichi-onp-k8s-cp-3 "sudo cat /var/log/cloud-init-output.log"
ssh seichi-onp-k8s-wk-1 "sudo cat /var/log/cloud-init-output.log"
ssh seichi-onp-k8s-wk-2 "sudo cat /var/log/cloud-init-output.log"
ssh seichi-onp-k8s-wk-3 "sudo cat /var/log/cloud-init-output.log"
```

- ローカル端末上でコマンド実行

```sh
# join_kubeadm_cp.yaml を seichi-onp-k8s-cp-2 と seichi-onp-k8s-cp-3 にコピー
scp seichi-onp-k8s-cp-1:~/join_kubeadm_cp.yaml ./
scp ./join_kubeadm_cp.yaml seichi-onp-k8s-cp-2:~/
scp ./join_kubeadm_cp.yaml seichi-onp-k8s-cp-3:~/

# seichi-onp-k8s-cp-2 と seichi-onp-k8s-cp-3 で kubeadm join
ssh seichi-onp-k8s-cp-2 "sudo kubeadm join --config ~/join_kubeadm_cp.yaml"
ssh seichi-onp-k8s-cp-3 "sudo kubeadm join --config ~/join_kubeadm_cp.yaml"

# join_kubeadm_wk.yaml を seichi-onp-k8s-wk-1 と seichi-onp-k8s-wk-2 と seichi-onp-k8s-wk-3 にコピー
scp seichi-onp-k8s-cp-1:~/join_kubeadm_wk.yaml ./
scp ./join_kubeadm_wk.yaml seichi-onp-k8s-wk-1:~/
scp ./join_kubeadm_wk.yaml seichi-onp-k8s-wk-2:~/
scp ./join_kubeadm_wk.yaml seichi-onp-k8s-wk-3:~/

# seichi-onp-k8s-wk-1 と seichi-onp-k8s-wk-2 と seichi-onp-k8s-wk-3 で kubeadm join
ssh seichi-onp-k8s-wk-1 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
ssh seichi-onp-k8s-wk-2 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
ssh seichi-onp-k8s-wk-3 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
```

- 軽い動作チェック

```sh
ssh seichi-onp-k8s-cp-1 "kubectl get node && kubectl get pod -A"
```

## cleanup

- proxmoxのホストコンソール上で以下コマンド実行。ノードローカルにいるVMしか操作できない為、全てのノードで打って回る。

```sh
# stop vm
## on unchama-sv-prox01
qm stop 1001
qm stop 1101
## on unchama-sv-prox02
qm stop 1002
qm stop 1102
## on unchama-sv-prox04
qm stop 1003
qm stop 1103

# delete vm
## on unchama-sv-prox01
qm destroy 9050 --destroy-unreferenced-disks true --purge true
qm destroy 1001 --destroy-unreferenced-disks true --purge true
qm destroy 1101 --destroy-unreferenced-disks true --purge true
## on unchama-sv-prox02
qm destroy 1102 --destroy-unreferenced-disks true --purge true
qm destroy 1002 --destroy-unreferenced-disks true --purge true
## on unchama-sv-prox04
qm destroy 1003 --destroy-unreferenced-disks true --purge true
qm destroy 1103 --destroy-unreferenced-disks true --purge true
```

- cleanup後、同じVMIDでVMを再作成できなくなることがあるが、proxmoxホストの再起動で解決する。(複数ノードで平行してcleanupコマンド実行するとだめっぽい)
