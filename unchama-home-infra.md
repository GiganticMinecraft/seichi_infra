# unchama-home-infra

## gen01(現用)

### Networking

- segmentationはなし

### Storage

- 共用ストレージとしてProxmoxクラスター上にcephクラスターが存在 ただしcephはIOが出ないので実質ほとんどローカルで持ってる
- 10GAll-FlashNASを買ったけど現在は検証環境Proxmoxクラスターの共用ストレージとしてのみ利用

![図](./diagrams/unchama-home-infra-gen01.drawio.svg)

## gen02(次期構想)

### Networking

- segmentationを導入し、`Service Network`と`SAN(Storage Area Network)`,`Management Network`など、用途ごとに分離する

### Storage

- 共用ストレージとして10GAll-FlashNASを全面導入する
- cephは廃止の方向とする

![図](./diagrams/unchama-home-infra-gen02.drawio.svg)
