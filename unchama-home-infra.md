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
- 検証環境に10Gを導入(スイッチ入替前提)
- 検証環境と本番環境の`Management Network`は分離するか一緒にするか検討の余地あり(両環境は目的が違うインフラなのでACLは別々が良さそうと思っている)

### Storage

- 共用ストレージとして10GAll-FlashNASを全面導入する
- cephは廃止の方向とする

![図](./diagrams/unchama-home-infra-gen02.drawio.svg)
