# unchama-home-infra

## gen01(現用)

### Networking

- segmentationはなし

### Storage

- 共用ストレージとしてProxmoxクラスター上にcephクラスターが存在 ただしcephはIOが出ないので実質ほとんどローカルで持ってる
- 10GAll-FlashNASを買ったけど現在は検証環境Proxmoxクラスターの共用ストレージとしてのみ利用

## Virtualization

- Proxmox
- 検証環境でkubevirt検証
  - `Control Plane`はProxmox上にVM建てる
  - `node`は`unchama-tst-kubevirt01`と`unchama-tst-kubevirt02`を利用(intel NUC)

![図](./diagrams/unchama-home-infra-gen01.drawio.svg)

## gen02(次期構想)

### Networking

- segmentationを導入し、`Service Network`と`SAN(Storage Area Network)`,`Management Network`など、用途ごとに分離する
- 検証環境に10Gを導入(スイッチ入替前提)
- 検証環境と本番環境の`Management Network`は分離するか一緒にするか検討の余地あり(両環境は目的が違うインフラなのでACLは別々が良さそうと思っている)

### Storage

- 共用ストレージとして10GAll-FlashNASを全面導入する
  - 本番環境の移行対象は20220321現在で2TiB程度(Ceph上のVMデータとLocalDiskのVMデータの合算)
- cephは廃止の方向とする

## Virtualization

- Proxmox
- kubevirtの適用範囲要検討(検証次第)

### 要追加機材

- 検証環境 Proxmox 10G NIM x3
  - 付随するSFP+トランシーバーとケーブルも必要(対向分も)
- 本番環境 Proxmox 1G NIC x3
- 検証環境 AT-x510-28GTX x1
- ログイン踏み台 x1
  - 置き方を要検討(VM？物理？)
  - 1個じゃなくて2個必要かも(本番環境と検証環境でACL分ける)

![図](./diagrams/unchama-home-infra-gen02.drawio.svg)
