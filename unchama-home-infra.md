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

| hostname | 名称 | 形態 | CPU | MEM | NIC | 備考 |
| -------- | --- | ---- | --- | --- | --- | --- |
| unchama-sv-prox01 | 本番proxmox#1 | 自作PC | AMD Ryzen 5 3600 (6C12T) | 64GB DDR4 | Onboard:1Gx1,PCI:10Gx1 | |
| unchama-sv-prox02 | 本番proxmox#2 | 自作PC | Intel Core i7-8700K (6C12T) | 64GB DDR4 | Onboard:1Gx1,PCI:10Gx1 | |
| unchama-sv-prox04 | 本番proxmox#4 | 自作PC | Intel Core i7-6800K (6C12T) | 64GB DDR4 | Onboard:1Gx2,PCI:10Gx1 | |
| seichi-cloud | 10G ALL Flash NAS 本番/検証併用 | NAS | AMD Ryzen V1500B quad-core 2.2 GHz | 4GB DDR4 ECC SODIMM | Onboard:1Gx4,PCI:10Gx2 | Synology DS1621+ |
| unchama-sv-dt2 | 本番ubuntu機 | 自作PC | Intel Core i5-6600K (4C4T) | 48GB DDR4 | Onboard:1Gx1 | 上のサービスを移行次第廃止予定 |
| unchama-sv-nas3 | 本番NAS DS218+ | NAS | Intel Celeron J3355 (2C2T) | 10GB DDR4 SODIMM | Onboard:1Gx1 | Synology DS218+ |
| seichi-nas04 | 本番NAS DS216j | NAS | Marvell Armada 385 88F6820 dual-core 1.0GHz | 512MB DDR3 | Onboard:1Gx1 | Synology DS216j |
| unchama-tst-prox01 | 検証proxmox#1 | 自作PC | Intel Core i5 9500  (6C6T)  | 32GB DDR4 | Onboard:1Gx1,PCI:1Gx1 | |
| unchama-tst-prox03 | 検証proxmox#3 | 自作PC | Intel Core i7 8700K (6C12T) | 32GB DDR4 | Onboard:1Gx1,PCI:1Gx1 | |
| unchama-tst-prox04 | 検証proxmox#4 | 自作PC | Intel Core i3 6100  (2C4T)  | 32GB DDR4 | Onboard:1Gx1,PCI:1Gx1 | |
| - | 検証用NAS DS116 | NAS | Marvell ARMADA 385 88F6820 dual-core 1.8GHz | 1GB DDR3 | Onboard:1Gx1 | Synology DS116 |
| unchama-tst-kubevirt01 | kubevirt検証用ubuntu#1 | Intel NUC | intel Core i5 10210U (4C8T) | 32GB DDR4 | Onboard:1Gx1,USB:1Gx1 | |
| unchama-tst-kubevirt02 | kubevirt検証用ubuntu#2 | Intel NUC | intel Core i5 10210U (4C8T) | 32GB DDR4 | Onboard:1Gx1,USB:1Gx1 | |

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
