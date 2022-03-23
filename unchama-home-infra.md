# unchama-home-infra

## gen01(現用)

### Networking

- segmentationはなし

### Storage

- 共用ストレージとしてProxmoxクラスター上にcephクラスターが存在 ただしcephはIOが出ないので実質ほとんどローカルで持ってる
- 10GAll-FlashNASを買ったけど現在は検証環境Proxmoxクラスターの共用ストレージとしてのみ利用

### Virtualization

- Proxmox
- 検証環境でkubevirt検証
  - `Control Plane`はProxmox上にVM建てる
  - `node`は`unchama-tst-kubevirt01`と`unchama-tst-kubevirt02`を利用(intel NUC)

![図](./diagrams/unchama-home-infra-gen01.drawio.svg)

## gen02(次期構想)

### Networking

- segmentationを導入し、`Service Network`と`SAN(Storage Area Network)`,`Management Network`など、用途ごとに分離する
- 検証環境に10Gを導入(スイッチ入替前提)
- 本番環境と検証環境のネットワークはアクセス制御の観点から完全分離する(相互環境に跨ぐセグメントは作らない)

### Storage

- 共用ストレージとして10GAll-FlashNASを全面導入する
  - 本番環境の移行対象は20220321現在で2TiB程度(Ceph上のVMデータとLocalDiskのVMデータの合算)
- cephは廃止の方向とする

### Virtualization

- Proxmox
- kubevirtの適用範囲要検討(検証次第)

### 要追加機材

- 検証環境 Proxmox 10G NIM x3
  - 付随するSFP+トランシーバーとケーブルも必要(対向分も)
  - 10G NIMの調達が難しいと思うので一旦1G NICで代用
- 本番環境 Proxmox 1G NIC x2
  - unchama-sv-prox01 x1
  - unchama-sv-prox02 x1
- 検証環境 AT-x510-28GTX x1
- ログイン用踏み台サーバー
  - Proxmoxクラスター上のVMとして用意
  - 2個用意済(本番環境1VM,検証環境1VM)

![図](./diagrams/unchama-home-infra-gen02.drawio.svg)
