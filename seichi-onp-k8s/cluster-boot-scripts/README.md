# seichi-onp-k8s / cluster-boot-scripts

オンプレミス上に整地鯖用のKubernetesクラスタをデプロイするためのスクリプト群です。
構築の前提としているオンプレ環境については、[オンプレ環境の前提](#オンプレ環境の前提)を参照してください。

## オンプレ環境の前提

### VM 環境

VM環境は `Proxmox Virtual Environment 7.1-11` を利用しています。
 - 3ノードクラスタ構成
 - AMDとIntelが混在しているので、アーキテクチャを跨いだLive Migrationは不可

KubernetesノードのVMは cloudinit イメージで作成されています。
この cloudinit イメージのベースには `Ubuntu 20.04 LTS` を利用しています。

### ストレージ

以下のストレージを共有ストレージとして使用しています。
 - Synology NAS(DS1621+)

### ネットワーク

以下のネットワークセグメントを切っています。
 - Service Network (192.168.0.0/20)
 - Storage Network (192.168.16.0/22)
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

## Kubernetesクラスタの構成

2022/05/23現在、クラスタは (3 control plane nodes + 3 worker nodes) の構成で[作成されています](https://github.com/GiganticMinecraft/seichi_infra/blob/9b6a9346371b8f2add3a786b6badbe4e13d4464c/seichi-onp-k8s/cluster-boot-scripts/deploy-vm.sh#L14-L19)。

クラスタの作成は以下のツール群で行っています。
  - kubeadm, kubectl, kubelet v1.24.0

CNI には Cilium を利用しています。


## 作成フロー

### 概要

以下に列挙した、[オンプレ環境の前提](#オンプレ環境の前提)を満たすために必要な作業の詳細は、当ディレクトリでは管理しないこととします。
 - ベアメタルなProxmox環境の構築
 - Snippetが配置可能な共有ストレージの構築
 - VM Diskが配置可能な共有ストレージの構築
 - Network周りの構築

後述する手順で `deploy-vm.sh` を実行すると、k8sクラスタの構築に利用するVMテンプレートが作成されたのち、k8sクラスタのノードとなるVMが沸きます。

その後、`cp-1` を最初のマスターノードとして、作成した全ノードをクラスタ内に引き込みます。

### 手順

 1. **proxmoxをホストしている物理マシンのターミナル上で**、以下のスクリプトで `deploy-vm.sh` を実行します。
 
    `TARGET_BRANCH` は、デプロイ対象のコード(`deploy-vm.sh` 及び `scripts/` 内のスクリプト)及び設定ファイル(`snippets/`)への変更が反映されたブランチを指定してください。

    ```sh
    export TARGET_BRANCH=main
    /bin/bash <(curl -s https://raw.githubusercontent.com/GiganticMinecraft/seichi_infra/${TARGET_BRANCH}/seichi-onp-k8s/cluster-boot-scripts/deploy-vm.sh) ${TARGET_BRANCH}
    ```

 1. ローカル端末から全ノードに接続できるようにします。

    1. `~/.ssh/config` に以下を追記してください。

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

    1. 以下のコマンドをローカル端末で実行してください。

        ```bash
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
        ```

        ```bash
        # 最初のコントロールプレーンのkubeadm initが終わっているかチェック
        ssh seichi-onp-k8s-cp-1 "kubectl get node -o wide && kubectl get pod -A -o wide"

        # cloudinitの実行ログチェック(トラブルシュート用)
        ssh seichi-onp-k8s-cp-1 "sudo cat /var/log/cloud-init-output.log"
        ssh seichi-onp-k8s-cp-2 "sudo cat /var/log/cloud-init-output.log"
        ssh seichi-onp-k8s-cp-3 "sudo cat /var/log/cloud-init-output.log"
        ssh seichi-onp-k8s-wk-1 "sudo cat /var/log/cloud-init-output.log"
        ssh seichi-onp-k8s-wk-2 "sudo cat /var/log/cloud-init-output.log"
        ssh seichi-onp-k8s-wk-3 "sudo cat /var/log/cloud-init-output.log"
        ```

 1. 作成した全ノードをクラスタ内に引き込みます。

    以下のコマンドをローカル端末で実行してください。

    ```sh
    # join_kubeadm_cp.yaml を seichi-onp-k8s-cp-2 と seichi-onp-k8s-cp-3 にコピー
    scp -3 seichi-onp-k8s-cp-1:~/join_kubeadm_cp.yaml seichi-onp-k8s-cp-2:~/
    scp -3 seichi-onp-k8s-cp-1:~/join_kubeadm_cp.yaml seichi-onp-k8s-cp-3:~/

    # seichi-onp-k8s-cp-2 と seichi-onp-k8s-cp-3 で kubeadm join
    ssh seichi-onp-k8s-cp-2 "sudo kubeadm join --config ~/join_kubeadm_cp.yaml"
    ssh seichi-onp-k8s-cp-3 "sudo kubeadm join --config ~/join_kubeadm_cp.yaml"

    # join_kubeadm_wk.yaml を seichi-onp-k8s-wk-1 と seichi-onp-k8s-wk-2 と seichi-onp-k8s-wk-3 にコピー
    scp -3 seichi-onp-k8s-cp-1:~/join_kubeadm_wk.yaml seichi-onp-k8s-wk-1:~/
    scp -3 seichi-onp-k8s-cp-1:~/join_kubeadm_wk.yaml seichi-onp-k8s-wk-2:~/
    scp -3 seichi-onp-k8s-cp-1:~/join_kubeadm_wk.yaml seichi-onp-k8s-wk-3:~/

    # seichi-onp-k8s-wk-1 と seichi-onp-k8s-wk-2 と seichi-onp-k8s-wk-3 で kubeadm join
    ssh seichi-onp-k8s-wk-1 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
    ssh seichi-onp-k8s-wk-2 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
    ssh seichi-onp-k8s-wk-3 "sudo kubeadm join --config ~/join_kubeadm_wk.yaml"
    ```

 1. コントロールプレーンの全ノードにkubeconfigを配布します。

    以下のコマンドをローカル端末で実行してください。

    ```bash
    ssh seichi-onp-k8s-cp-2 "mkdir -p \$HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config &&sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
    ssh seichi-onp-k8s-cp-3 "mkdir -p \$HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config &&sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
    ```

 1. 軽い動作チェック

    以下のコマンドをローカル端末で実行してください。

    ```sh
    ssh seichi-onp-k8s-cp-1 "kubectl get node -o wide && kubectl get pod -A -o wide"
    ssh seichi-onp-k8s-cp-2 "kubectl get node -o wide && kubectl get pod -A -o wide"
    ssh seichi-onp-k8s-cp-3 "kubectl get node -o wide && kubectl get pod -A -o wide"
    ```

## クラスタ操作

### コントロールプレーンのノードを経由してクラスタを操作する

作成フローが完了した時点で、Proxmox上に `seichi-onp-k8s-cp-[1-3]` で識別される VM が作成されているはずです。以下、これらの VM の事を「CPノード」と呼びます。CPノードである VM は、k8s クラスタのコントロールプレーンノードとして機能しています。

3 つあるCPノードのうちの一つにSSHでログインし、 `kubectl` を利用することでクラスタを操作することができます。

---

__**アクセス権限について**__

CPノードにアクセスするのに必要な権限は、
 - 「オンプレネットワークの踏み台サーバー」へのSSH権限
 - CPノードの `cloudinit` ユーザーの `authorized_keys` に自身の公開鍵が登録されている ([CPノードのログインに利用できる公開鍵について](#CPノードのログインに利用できる公開鍵について)を参照)

の二つです。もし権限が不足している場合は、サーバー管理者に権限を要求してください。

---

以下、前提として、踏み台サーバーへの接続情報は `~/.ssh/config` にすでに記載されているものとします。
CPノードへSSHでログインするには、作業者のローカル端末で以下の手順を実行してください。

 1. `~/.ssh/config` にCPノードへの接続情報を追記する

    もしCPノードへの接続情報が `~/.ssh/config` にすでに記載されていない場合、以下の手順を実行してください。

    1. ターミナルで次のスクリプトを実行し、必要なパラメータをセットする。

        ```bash
        IDENTITY_FILE_PATH=<接続に利用する秘密鍵へのパス>
        BASTION_HOST_NAME=<踏み台サーバーのホスト名>
        ```

    1. 次のスクリプトを実行し、踏み台サーバーを介した接続に必要な設定を生成する。

        ```bash
        ssh_additional_config=$(cat <<EOF
        Host seichi-onp-k8s-cp-1
          HostName 192.168.18.11
          User cloudinit
          IdentityFile ${IDENTITY_FILE_PATH}
          ProxyCommand ssh -W %h:%p ${BASTION_HOST_NAME}

        Host seichi-onp-k8s-cp-2
          HostName 192.168.18.12
          User cloudinit
          IdentityFile ${IDENTITY_FILE_PATH}
          ProxyCommand ssh -W %h:%p ${BASTION_HOST_NAME}

        Host seichi-onp-k8s-cp-3
          HostName 192.168.18.13
          User cloudinit
          IdentityFile ${IDENTITY_FILE_PATH}
          ProxyCommand ssh -W %h:%p ${BASTION_HOST_NAME}
        EOF
        )
        ```

    1. 次のスクリプトを実行する。

        ```bash
        echo "${ssh_additional_config}" >> ~/.ssh/config
        ```

       もし生成された設定を確認したい場合は、 `echo "${ssh_additional_config}"` のみを実行してください。

 1. 前回接続した後にクラスタが再作成されている場合は、以下のコマンドで `known_hosts` の登録を削除してください。

    ```sh
    ssh-keygen -R 192.168.18.11
    ssh-keygen -R 192.168.18.12
    ssh-keygen -R 192.168.18.13
    ```

    `known_hosts` の登録を削除する必要がある理由は、VMを作り直す度にホストの公開鍵が変わるためです。

 1. 以下のコマンドを実行して接続チェック、及びクラスタへのアクセスができることの確認を行ってください。

    ```sh
    ssh seichi-onp-k8s-cp-1 "kubectl get node -o wide && kubectl get pod -A -o wide"
    ssh seichi-onp-k8s-cp-2 "kubectl get node -o wide && kubectl get pod -A -o wide"
    ssh seichi-onp-k8s-cp-3 "kubectl get node -o wide && kubectl get pod -A -o wide"
    ```

---

#### CPノードのログインに利用できる公開鍵について

CPノードへのログインに利用できる鍵ペアは、クラスタを作成するタイミングで固定されています。

<details>
<summary>詳細</summary>

より具体的には、[`deploy-vm.sh`](./deploy-vm.sh)で作成される cloud-config (特に、user-config) で、GitHubに登録してある、CPノードへのアクセス権を与えたいユーザーの公開鍵を `/home/cloudinit/.ssh/authorized_keys` に書き込むように[設定](https://github.com/GiganticMinecraft/seichi_infra/blob/9b6a9346371b8f2add3a786b6badbe4e13d4464c/seichi-onp-k8s/cluster-boot-scripts/deploy-vm.sh#L98-L100)しています。

</details>

クラスタの再作成を伴わずにログイン可能な公開鍵を追加したい場合は、**全CPノード**の `/home/cloudinit/.ssh/authorized_keys` に追記してください。合わせて、次回のクラスタ作成時に反映されるよう、[`deploy-vm.sh`](./deploy-vm.sh)で作成される user-config の `runcmd:` 内への追記も行ってください。

### インターネットを介してクラスタを操作する

オンプレ環境の内部ネットワーク内からクラスタを操作する場合、各環境(検証用クラスタと本番用クラスタ)のHAProxyに持たせた k8s API Endpoint の VIP に接続することができます。

一方、API Endpointにインターネットから直接接続するための経路は、DoS攻撃等の懸念から設けていません。しかしながら、Terraform Cloud からリソースを注入する等の目的で、インターネットからクラスタAPIへの到達経路が必要となることがあります。

そこで、次のようなセットアップを行っています。

 - まず、クラスタのセットアップスクリプトにより、`k8s-api.onp-k8s.admin.local-tunnels.seichi.click` がクラスタAPIのSSL証明書のSAN(Subject Alternative Name)に追記されており、かつ、このドメイン(`k8s-api.onp-k8s.admin.local-tunnels.seichi.click`) は `127.0.0.1` を向くように[設定されて](../../terraform/cloudflare_dns_records.tf)います。

 - 次に、k8s クラスタ内に、 k8s API Endpoint を `k8s-api.onp-k8s.admin.seichi.click` に張った TCP Argo Tunnel でアクセスできるようにするための `cloudflared` インスタンスを常駐させています。

よって、`k8s-api.onp-k8s.admin.seichi.click` 上のトンネルへのアクセス権限がある任意の個人及びサービスは、 `127.0.0.1` の適当なポートに `k8s-api.onp-k8s.admin.seichi.click` へのトンネルを生やすことで、ローカル環境の `kubectl` 等が直接 API に問い合わせることができるようになります。

`k8s-api.onp-k8s.admin.seichi.click` 上のトンネルのアクセス制御の詳細は [`cloudflare_network_admin_services`](../../terraform/cloudflare_network_admin_services.tf)を参照してください。

## クラスタの削除

クラスタを再作成する場合は、事前に以下の手順でクラスタの削除を行って下さい。

- proxmoxのホストコンソール上で以下コマンド実行。ノードローカルにいるVMしか操作できない為、全てのノードで打って回る。

```sh
# stop vm
## on unchama-sv-prox01
ssh 192.168.16.150 qm stop 1001
ssh 192.168.16.150 qm stop 1101
## on unchama-sv-prox02
ssh 192.168.16.151 qm stop 1002
ssh 192.168.16.151 qm stop 1102
## on unchama-sv-prox04
ssh 192.168.16.153 qm stop 1003
ssh 192.168.16.153 qm stop 1103

# delete vm
## on unchama-sv-prox01
ssh 192.168.16.150 qm destroy 9050 --destroy-unreferenced-disks true --purge true
ssh 192.168.16.150 qm destroy 1001 --destroy-unreferenced-disks true --purge true
ssh 192.168.16.150 qm destroy 1101 --destroy-unreferenced-disks true --purge true
## on unchama-sv-prox02
ssh 192.168.16.151 qm destroy 1102 --destroy-unreferenced-disks true --purge true
ssh 192.168.16.151 qm destroy 1002 --destroy-unreferenced-disks true --purge true
## on unchama-sv-prox04
ssh 192.168.16.153 qm destroy 1003 --destroy-unreferenced-disks true --purge true
ssh 192.168.16.153 qm destroy 1103 --destroy-unreferenced-disks true --purge true
```

- cleanup後、同じVMIDでVMを再作成できなくなることがあるが、proxmoxホストの再起動で解決する。(複数ノードで平行してqm destroyコマンド実行すると 不整合が起こる模様)
