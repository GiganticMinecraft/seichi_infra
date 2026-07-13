# インフラ実態調査とドキュメントの乖離 (2026-07-08)

本文書は、稼働中のインフラを実測した結果と、リポジトリ内ドキュメントの記述を突き合わせた監査記録である。
「古くなっている記述」「ドキュメント間で矛盾している記述」「どこにも書かれていない重要な実態」の三つを列挙し、あわせて調査中に見つかった運用上の要注意事項を記録する。

調査は 2026-07-08 に、次の読み取り専用の経路で行った。

- Proxmox API(PVEAuditor 権限のトークン、`.claude/skills/proxmox/scripts/pve` 経由)
- ArgoCD API と Grafana API(それぞれ MCP 経由)
- Prometheus と Loki(Grafana データソース経由)
- リポジトリ本体と GitHub API(workflows、secrets 名、environments)

数値はすべて調査時点のスナップショットである。

## 1. 古くなっている記述

実測と食い違うことを確認できた記述を、影響が大きい順に挙げる。

> **対応状況 (2026-07-08 追記)**: #1〜#12 と #14 は同日中にドキュメントへ反映した(#9 は設計書冒頭へのステータス追記、#11 はルート README への注記、#7 は現配置での手順書き換え + 実行前確認の注意書き追加、による対応)。
> 未対応は #13(proxmox-upgrade runbook の TODO 埋め。手順そのものの新規執筆が必要)のみ。

| # | ドキュメントの記述 | 実態 | 該当ファイル |
|---|---|---|---|
| 1 | 「独自プラグイン込みのマイクラ鯖は現時点で VM のみ運用方針確立」 | mcserver--s1/s2/s3/s5/s7/lobby/kagawa/one-day-to-reset の 8 系統が k8s の `seichi-minecraft` namespace で稼働中。VM のマイクラ鯖は存在しない | `DEPLOYMENT.md` |
| 2 | 「投票受付サーバーはまだ k8s 上に乗っていない」 | `mcserver--votelistener` が存在し VIP 10.96.0.136 を保持 | `seichi-onp-k8s/manifests/seichi-kubernetes/README.md` |
| 3 | VIP 10.96.0.132〜135 は RedisBungee / BungeeSemaphore 用 Redis | 当該 Redis の yaml は消滅し、valkey(redisbungee-valkey、bungeesemaphore-valkey)に置換済み。LB IP 注釈も付いていない | 同上 |
| 4 | Proxmox VE 9.1.2 | 実測 9.2.4(9 ノードすべて) | `docs/guides/cluster-setup.md`、`seichi-onp-k8s/cluster-boot-up/README.md` |
| 5 | kubeadm / kubelet v1.34.2 | クラスタは v1.36.2 で稼働(ArgoCD が報告するサーバーバージョン) | `docs/guides/cluster-setup.md` |
| 6 | NAS は「10Gbps、合計 7TB の SSD」 | 共有ストレージは TrueNAS 3 台(iSCSI LUN 計約 17 TiB)+ Synology 2 台(iSCSI 計約 5.5 TiB + NFS 計約 4.4 TiB)+ PBS(datastore 計約 4.8 TiB)。7TB という合計はどの組み合わせとも一致しない | `DEPLOYMENT.md`、`docs/guides/deployment.md` |
| 7 | クラスタ削除手順に unchama-sv-prox02(192.168.16.151)が登場 | prox02 は現存しない(prox02 と prox07 は欠番)。k8s VM の現配置も手順記載の 3 ホストと異なり、CP が prox01/03/06、WK が prox09/10/11 に分散 | `seichi-onp-k8s/cluster-boot-up/README.md` |
| 8 | 「main にマージ後、Wiki.js に自動同期」 | 現在は MkDocs を GitHub Pages にデプロイする方式(`deploy_docs.yaml`) | `docs/README.md` |
| 9 | Garage は image v2.2.0、chart 0.9.2、blockSize 1MiB、meta PVC 10Gi。Loki 切替と Thanos は「Phase 2〜3(別途計画)」 | 実際は chart v2.3.0、blockSize 64MiB、meta PVC 100Gi。Loki も Thanos も Pyroscope も Garage を本番利用中(バケット: loki、thanos、pyroscope、mariadb-backups、mc-worlds、seichiassist)。設計書に記載の `seichi-plugins` バケットは見当たらず、逆に `pyroscope` バケットは設計書に記載がない | `docs/plans/2026-03-01-garage-object-storage-design.md` |
| 10 | terraform/README.md の管理リソース一覧(自ら「2022/06/04 現在」と注記) | k8s 上の管理対象は Secret と Namespace に加え ArgoCD 本体のブートストラップ(helm_release)を含む。Cloudflare 側も Zero Trust Access アプリ 10 個、Pages プロジェクトなどに拡大 | `terraform/README.md`(最終更新 2022-06-04) |
| 11 | `diagrams/unchama-home-infra.drawio.svg` は Proxmox ホスト 4〜7 台の時代の図 | 現在は 9 台。図に存在しない DS1621+、TrueNAS 3 台、PBS(sc-proxbksrv-01)が主力機材になっている | `diagrams/`(最終更新 2022-01-29) |
| 12 | mkdocs.yml の nav に runbook 5 本 + guides 3 本のみ登録 | `rollback-mcserver-and-mariadb.md`(最新かつ最も実用的な runbook)と `docs/plans/` が nav 未登録で、GitHub Pages から辿れない | `mkdocs.yml` |
| 13 | proxmox-upgrade runbook | バックアップ、アップグレード、動作確認、ロールバックの全節が TODO のスケルトンのまま | `docs/runbooks/proxmox-upgrade.md` |
| 14 | cloudflared による k8s API 公開を「Argo Tunnel」と呼称 | Cloudflare は Argo Tunnel を Cloudflare Tunnel に改称済み(名称のみの問題) | `seichi-onp-k8s/cluster-boot-up/README.md` ほか |

## 2. ドキュメント間で矛盾している記述

どちらが正しいか本調査だけでは確定できないものを含むため、修正時には一次情報の確認が要る。

> **対応状況 (2026-07-08 追記)**: 一次情報を確認のうえ、5 件すべてを解消した。
>
> - #1: `k8s-node-setup.sh` と ansible の group_vars で VIP が 192.168.32.100(+ 192.168.0.100)であることを確認し、cluster-setup.md と cluster-boot-up README を修正。
> - #2: `main.tf` の variable 宣言(小文字)と変換スクリプトの `tr '[:upper:]' '[:lower:]'` を確認し、guides/terraform.md の「大文字」を訂正。
> - #3: GitHub Actions Secret に `TF_VAR_ONP_K8S_CLOUDFLARED_TUNNEL_CREDENTIAL` が実在することを確認し、runbook の「Terraform Cloud のシークレット」を訂正。
> - #4: cluster-boot-up README に「踏み台経由は初期構築時の経路で、日常アクセスは tailscale 経由」の注記を追加。
> - #5: terraform/README.md の制約記述を「2022 年時点の制約(現行 HCP Terraform では未再検証)」に改めた。

| # | 論点 | 記述 A | 記述 B | 実態からの補足 |
|---|---|---|---|---|
| 1 | k8s API Endpoint の VIP | 192.168.18.100(`cluster-boot-up/README.md`) | スクリプト実体(`k8s-node-setup.sh`)は keepalived + HAProxy で 192.168.32.100(ens20)と 192.168.0.100(ens18) | 192.168.32.0/x セグメントはどのネットワーク一覧にも記載がない |
| 2 | Terraform variable の命名規則 | 「すべて大文字のスネークケース」(`docs/guides/terraform.md`) | 「すべて小文字のスネークケース」(`terraform/README.md`) | GitHub Secrets の実名は `TF_VAR_大文字`。変換スクリプトを挟む設計なので、Secret 名と variable 名で規則が違う可能性が高く、guides 側の要約が不正確とみられる |
| 3 | Cloudflare Tunnel 証明書の格納先 | Terraform Cloud のシークレット(`docs/runbooks/cloudflare-cert-renewal.md`) | GitHub Actions Secret `TF_VAR_ONP_K8S_CLOUDFLARED_TUNNEL_CREDENTIAL`(他文書のフロー説明) | GitHub Secrets に同名のシークレットが実在する |
| 4 | CP/WK への SSH 経路 | 踏み台 + ProxyCommand で 192.168.18.11〜23 へ(`cluster-boot-up/README.md`) | tailscale 経由で `seichi-onp-k8s-cp-{1,2,3}.seichi.internal` へ(`rollback-mcserver-and-mariadb.md`、2026-04 更新) | 後者が新しい。tailscale の導入自体がどこにも文書化されていない(後述) |
| 5 | Terraform 実行の制約 | 「cloudflared のトンネルを apply 前に張る必要があり、2022/06/04 現在 Terraform Cloud では不可能」(`terraform/README.md`) | 現在も GitHub Actions 実行 + Terraform Cloud は state 管理のみ、という構成は一致 | 制約の根拠が 4 年前の情報なので、再検証しないまま新しい文書に転記しないほうがよい |

## 3. どこにも書かれていない重要な実態

manifests やスクリプトを読めば断片は分かるが、まとまった文書が存在しない領域を、今回の実測値とともに記す。
この節がそのまま新規ドキュメントの下書きになることを意図している。

### 3.1 Proxmox クラスタの全体像

クラスタ `seichi-network` は 9 ノード(prox01、prox03〜06、prox08〜11。02 と 07 は欠番)で、全ノードオンライン、quorate。
ノードのドキュメントは削除手順に 3 台の IP が出る程度で、ホスト一覧すら存在しない。

| ノード | IP (管理) | CPU | スレッド | RAM | 主な載せ物 |
|---|---|---|---|---|---|
| prox01 | 10.123.0.150 | i5-13500 | 20 | 126 GiB | k8s cp-3、netbox、redmine、dns02、テンプレート群 |
| prox03 | 10.123.0.152 | Ryzen 7 5700X | 16 | 126 GiB | k8s cp-1、PBS VM、prometheus-production |
| prox04 | 10.123.0.153 | Ryzen 7 8700G | 16 | 92 GiB | (遊休。stopped の負荷試験 VM のみ) |
| prox05 | 10.123.0.154 | 未確認 | 20 | 94 GiB | (遊休) |
| prox06 | 10.123.0.155 | i9-13900H | 20 | 94 GiB | k8s cp-2、nextcloud |
| prox08 | 10.123.0.157 | 未確認 | 20 | 94 GiB | (遊休。stopped の streaming VM のみ) |
| prox09 | 10.123.0.158 | Ryzen 9 9955HX | 32 | 92 GiB | k8s wk-1 |
| prox10 | 10.123.0.159 | Ryzen 9 9955HX | 32 | 92 GiB | k8s wk-2 |
| prox11 | 10.123.0.160 | Ryzen 9 9955HX | 32 | 92 GiB | k8s wk-3 |

CPU 世代と RAM 容量が完全に混在しているため、ライブマイグレーションの互換性は VM 側の CPU タイプ設定(現状 x86-64-v3)に依存する。
PVE の HA 管理下にあるのは vm:101(PBS)と vm:120(redmine)の 2 台だけで、k8s VM はローカルディスクを使うため HA 対象外である。
VM は QEMU 21 台(稼働 12、停止 5、テンプレート 4 世代)で、LXC コンテナは使っていない。

リソース集約率は次のとおり(テンプレート除外、稼働 VM の割当合計)。

| ノード | 割当 vCPU / 物理スレッド | 割当 mem / 物理 RAM | CPU 実使用 | ノード実 mem |
|---|---|---|---|---|
| prox01 | 10/20 (0.50x) | 30/126 GiB (0.24x) | 0.24 core | 23% |
| prox03 | 12/16 (0.75x) | 48/126 GiB (0.38x) | 0.47 core | 33% |
| prox06 | 8/20 (0.40x) | 32/94 GiB (0.34x) | 0.33 core | 34% |
| prox09 | 24/32 (0.75x) | 90/92 GiB (0.98x) | 2.72 core | 80% |
| prox10 | 24/32 (0.75x) | 90/92 GiB (0.98x) | 2.45 core | 95% |
| prox11 | 24/32 (0.75x) | 90/92 GiB (0.98x) | 2.86 core | 88% |
| クラスタ計 | 102/208 (0.49x) | 380/901 GiB (0.42x) | 実効 5% 未満 | — |

CPU はクラスタ全体で大幅な余剰(オーバーコミットどころか 0.49x)である一方、ワーカー 3 ノードは物理 RAM 92 GiB に対し単一 VM へ 90 GiB を割り当てており、メモリが実質の制約になっている。
prox04/05/08 の 3 台は稼働 VM ゼロの遊休ノードで、増設の受け皿になり得るが RAM は 1 台 96 GB が上限である。

ワーカー間には非対称がある。
wk-1/wk-2 は OS ディスクもノードローカル(local-lvm)だが、wk-3 だけ OS ディスクが共有 LVM(prd-network-01-lun01)上にある。
また prox03 だけ未使用の `local-lvm-02`(約 0.93 TiB)を持つ。

### 3.2 ノードのネットワーク構成

Proxmox 側の vmbr 構成はどこにも文書化されていない。実測では全ノード同一パターンで、次の構成である。

- 管理専用 NIC 1 本: 10.123.0.15x/23(VLAN999、GW 10.123.1.254)。corosync と管理トラフィックはここを通る。
- bond0: LACP(802.3ad)、スレーブ NIC 2 本。VM トラフィックはすべてこの bond 上の VLAN サブインターフェース経由。
- ブリッジ 4 本(vlan-aware ではなく、VLAN サブインターフェースを 1 本ずつ収容):

| ブリッジ | VLAN | ホスト IP | 用途 |
|---|---|---|---|
| vmbr0 | 100 | 192.168.1.15x/22 | VM サービス網。全 VM の net0 |
| vmbr1 | 110 | 192.168.16.15x/22 | ストレージ網。iSCSI、k8s VM の net1 |
| vmbr2 | 120 | なし | k8s ノード専用セグメント(net2) |
| vmbr3 | 999 | なし | VM を管理 VLAN に直結するためのブリッジ |

ドキュメントのネットワーク一覧(cluster-setup.md ほか)にはこのうち 192.168.32.0/x(k8s API VIP がいるセグメント)と管理 VLAN の記載がない。
細かい点として、bond 設定に `bond-million 100` という記載がある(`bond-miimon 100` の typo とみられる。動作への影響は未確認)。

### 3.3 ストレージの全体像

CSI ドライバーの使い分けを説明する文書がない(democratic-csi のセットアップ手順のみ存在)。
実測での全体像は次のとおり。

物理層は NAS 5 台と PBS 1 台である。

| 機器 | IP | 提供方式 | 用途と使用率 |
|---|---|---|---|
| sc-truenas-01 | 192.168.16.231 | iSCSI | PVE 共有 LVM 3.08 TiB、使用 89% |
| sc-truenas-02 | 192.168.16.232 | iSCSI | PVE 共有 LVM 3.08 TiB、使用 90% |
| sc-truenas-03 | 192.168.16.234 | iSCSI | PVE 共有 LVM 11 TiB(使用 20%)+ democratic-csi 経由で k8s へ |
| mktn-arigatonas (Synology) | 192.168.16.233 | iSCSI + NFS | PVE LVM 2.2 TiB + バックアップ NFS |
| seichi-cloud (Synology) | 192.168.16.240 | iSCSI + NFS + DSM API | PVE LVM 3.3 TiB + バックアップ NFS + synology-csi の DSM エンドポイント |
| sc-proxbksrv-01 (PBS) | 192.168.19.201 | Proxmox Backup Server | datastore 2 面 計 4.8 TiB、使用 71%、prune は keep-all |

k8s 側の StorageClass は 4 つで、default は `synology-iscsi-storage` である。

| StorageClass | バックエンド | 主な利用者 |
|---|---|---|
| synology-iscsi-storage (default) | seichi-cloud (btrfs) | MariaDB 500Gi、mcserver ワールド(例: s1 は 200Gi)、valkey、Garage meta |
| sc-truenas-03-iscsi | sc-truenas-03 (ext4) | Garage data 4Ti × 3 レプリカ |
| topolvm-provisioner | ノードローカル VG | garage バックアップ用ダンプ 400Gi |
| local-path | ノードローカル dir | 雑多 |

オブジェクトストレージは Garage(3 レプリカ、replication_factor 2)で、バケットは loki、thanos、pyroscope、mariadb-backups、mc-worlds、seichiassist。
アプリ層の対応は、RDB が MariaDB(mariadb-operator、500Gi、単一インスタンス)、KVS が valkey 3 系統、MQ が RabbitMQ、検索が Meilisearch、メトリクス長期保存が Prometheus(PVC 500Gi、retention 30d)から Thanos 経由で Garage、ログが Loki から Garage、トレースが Tempo(ローカル PVC 100Gi のみで S3 なし)、プロファイルが Pyroscope から Garage、である。

### 3.4 バックアップフロー

バックアップの全体像を述べた文書がなく、rollback runbook に断片が出るだけである。実測でのフローは次の 4 系統になる。

| フロー | スケジュール (JST) | 経路 |
|---|---|---|
| PVE VM バックアップ (vzdump) | 日次 | → PBS(keep-all)+ NFS 2 面(keep-daily=2, keep-weekly=1) |
| MariaDB 全 DB (CronWorkflow) | 毎日 04:00 | mariadb-operator の Backup CR → Garage `mariadb-backups`、保持 3 日 |
| mcserver ワールド (CronWorkflow) | 毎日 04:00(lobby は月曜 02:00) | STS を 0 にスケール → PVC を proxmox-backup-client で PBS へ直接送信 → 再 sync |
| Garage 二次バックアップ (CronWorkflow) | 毎日 10:00 | 全バケット(loki 除外)を topolvm PVC へ dump → PBS へ |

失敗時は Discord へ通知される。バックアップの終端はすべて PBS で、PBS 自体の構成、保持ポリシー(keep-all である点を含む)、リストア一般手順の文書がない。

### 3.5 監視スタック

監視は本リポジトリの管理対象として最大級の領域だが、文書はゼロに近い(2022 年の構成図に Grafana の URL ラベルが 1 つあるだけ)。
実態は次のとおり。

- Grafana データソース 7 件: Prometheus × 2、Loki、Tempo、Pyroscope、MariaDB、Parca(Parca のみ接続不能で、Pyroscope と重複する残骸とみられる)。
- ダッシュボード 49 枚、8 フォルダ(Cilium、Garage、Infrastructure、Kubernetes、Kyverno、MariaDB、Minecraft、OpenCost)。
- アラートは Prometheus 管理で 200 ルール超。Grafana 管理アラート、OnCall、Incident は未使用。
- メトリクス収集は Grafana Alloy(k8s-monitoring chart)、ログは Loki(Pod ログに加え監査ログ、イベント、systemd journal)、長期保存は Thanos。
- これとは別に、VM 上の旧監視基盤 prometheus-production(VM 104。elasticsearch と kibana が同居し、Minecraft ログとスイッチの sFlow を保管)が並存している。k8s 側監視との役割分担を述べた文書はない。

### 3.6 ArgoCD と GitOps の構造

DEPLOYMENT.md はルート app の場所を述べるだけで、規模感と構造の文書がない。

- Application 総数 128、AppProject 9。単一クラスタ(in-cluster)運用。
- 主リポジトリは本リポジトリ(95 app)で、残りは外部 Helm リポジトリ 33 app と、Thanos 専用の別リポジトリ `GiganticMinecraft/thanos-config`(jsonnet、tag 固定)。
- `cloudflared-tunnel-exits` パターン: 内部サービスごとに cloudflared Pod を 1 つ立てる ApplicationSet で、29 系統のトンネル(http 22、https 5、tcp 1 ほか)が動いている。この仕組みの文書がない。
- kustomize が主体(31 ディレクトリ)で、Helm は app-templates と基盤系 ApplicationSet に限られる。

### 3.7 アクセス経路と tailscale

管理アクセスの現行経路は tailscale(tailnet: ide-hadar.ts.net)で、`*.seichi.internal` の名前解決、CP への SSH、PBS GUI(`sc-proxbksrv-01.ide-hadar.ts.net:8007`)がこれに依存している。
`tailscale-approval-bot` という承認用アプリまで k8s 上に存在するにもかかわらず、tailscale の導入、アクセス権管理、デバイス承認フローを述べた文書が存在しない。
新規メンバーが rollback runbook を実行しようとすると、前提となる tailscale 参加手順がどこにもない状態になる。

### 3.8 Cilium BGP と LoadBalancer IPAM

LoadBalancer VIP の広告は Cilium BGP control plane(v2 API)で行われており、設定は `apps/cluster-wide-apps/cilium-networking/` にある。
manifests の Service 定義に `loadBalancerClass: io.cilium/bgp-control-plane` が現れる以外、仕組みの説明はどこにもない。

- 全 6 ノードがルーター 192.168.3.254(AS 65184)と eBGP ピアリングし、ノードごとに個別 ASN を持つ(cp-1〜3 = 65201〜65203、wk-1〜3 = 65301〜65303)。
- LB IPAM プールは 10.96.0.0/22 で、ドキュメントの「LoadBalancer VIP」記述と一致する。
- `CiliumBGPAdvertisement` は LoadBalancerIP に加えて **ClusterIP を全 Service 分広告**している(全マッチのセレクタ)。オンプレ網の VM から k8s の全 ClusterIP へ直接ルーティングできる設計であり、旧 Redis 用 LB VIP を廃止できたのはこのためとみられる。この設計判断は未文書化。
- 実測(2026-07-09、Prometheus)では BGP セッションは 6 本すべて Established、各ノードが 124 経路を広告中。
- 留意点: ピアは 1 台のみでルーター側の冗長がなく、ルーターの機種・設定はリポジトリ外(unchama 管理)。ASN 採番規則の由来も未記載。広告経路数は Service 追加のたびに増える。

### 3.9 GitHub 側の構成

- Secrets は約 90 個で、ほぼすべて `TF_VAR_*` 形式。一括で環境変数に注入するスクリプトを経由して Terraform に渡る。variables はなし、environments は github-pages のみ。
- workflows は 12 本(Terraform の plan/apply、コンテナイメージビルド 4 種、Helm チャート公開、MkDocs デプロイ、Pluto、shellcheck ほか)。
- 本リポジトリは `helm-charts/raw-resources` を GitHub Releases で公開する Helm リポジトリを兼ねる(ルートの `index.yaml`)。

## 4. 調査で見つかった運用上の要注意事項

ドキュメントの問題ではないが、調査中に判明した事項をここに記録する(2026-07-08 時点)。

1. **prox10 の実メモリ使用率が 95%**。prox09 も 80%、prox11 も 88% で、ワーカー 3 ノードに余裕がない。swap なしの構成なので、ホスト側のメモリ枯渇は VM の OOM に直結する。
2. **sc-truenas-01 と 02 の LUN 使用率が 89〜90%**。thin LVM ではなく通常 LVM なので即死はしないが、新規 VM ディスクの置き場がほぼない。
3. **prometheus-production(VM 104)の vzdump が直近 2 回連続で失敗**している(7/6 と 7/7、prox03)。他 VM のバックアップは成功している。
4. **PrometheusNotConnectedToAlertmanagers が firing** しており、アラート 200 ルールが評価されても通知が届かない状態の可能性が高い。実際に TargetDown(Minecraft 系メトリクスエンドポイント 8 件)、seichi-portal-backend の CrashLoopBackOff、KubeJobFailed(4 月の mariadb-restore Job 残骸 4 件など)計 16 インスタンスが warning で滞留している。
5. **prox03 からのみ sc-truenas-03 の LUN が status=unknown**。他ノードからは available で、マルチパスや iSCSI セッションの個別不調とみられる。
6. **PBS の datastore が使用率 71% かつ prune が keep-all**。mcserver ワールドと Garage ダンプを毎日受け続ける設定なので、放置すれば満杯になる。
7. ArgoCD で 4 app が OutOfSync(kyverno、seichi-minecraft-mariadb、seichi-minecraft-workflows、thanos)、1 app が Progressing(seichi-portal-backend。上記 CrashLoop と同根)。
8. Grafana の Parca データソースが接続不能(接続先サービスが存在しない)。Pyroscope に移行済みなら削除できる。

## 5. 対応の優先順位案

ドキュメント整備は、実際に人が困る順に行うのがよい。

1. **アクセス経路(tailscale)と PBS の runbook 新設**: 障害対応の前提なのに文書がない(3.7、3.4)。
2. **DEPLOYMENT.md と manifests README の陳腐化修正**: 「マイクラ鯖は VM のみ」「投票サーバーは未移行」「Redis の VIP」は、新規参加者の理解を直接誤らせる(1 節 #1〜3)。
3. **ストレージと監視の全体像ページ新設**: 本文書の 3.3、3.5 がそのまま下書きになる。
4. **mkdocs nav の修正**: rollback runbook が公開ドキュメントから辿れないのは登録漏れの 1 行修正で直る(1 節 #12)。
5. **2022 年の図と terraform/README.md**: 誤解の源泉として大きいが、書き直しコストも大きい。「歴史的文書」と冒頭に注記するだけでも当座の害は減る。
