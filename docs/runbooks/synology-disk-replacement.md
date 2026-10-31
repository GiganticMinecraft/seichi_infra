# Synology（seichi-cloud）の不良ディスクの交換

## 概要

`seichi-cloud`（DS1621+）のストレージプールで、ディスクに故障の兆候が出たときの交換手順。
`synology-iscsi-storage` の iSCSI LUN（mariadb、mcserver のワールドなど）はすべてこのプールにある。

**どのやり方で交換するかで、データが壊れるかどうかが変わる。** 2026-10 には、読めないセクタを出しながら
RAID から切り離されない SSD を DSM の「ドライブの交換」で入れ替えた結果、不良ディスクが返した誤った内容が
新しいディスクにコピーされ、mcserver s1 / s3 のワールドと mariadb の一部が恒久的に壊れた
（障害報告 #6653、10/29 04:00 へのロールバックで復旧）。

## 構成

- Storage Pool 1: SSD 5 台の RAID5（md2）+ ホットスペア 1 台
- 全ドライブの書き込みキャッシュは無効にしてある（新しく入れたドライブも無効にする）
- DSM の「Disk N」は物理スロット番号で、カーネルの `sataN` とは**番号が一致しない**（例: 2026-10-31 時点で Disk 5 = sata4、Disk 3 = sata2）。
  シリアルで突き合わせる
- 監視
  - grafana-onp のアラート「Synology のディスクで SMART の異常値が増加」（SMART の故障系の値が 24 時間で増えたら発火）
  - grafana-onp のダッシュボード「Synology ディスク健全性」（NAS フォルダ、uid `synology-disk-health`）

## 前提知識: なぜ「ドライブの交換」が危ないことがあるのか

| | DSM の「ドライブの交換」 | 不良ディスクを無効化してからリビルド |
|---|---|---|
| 新しいディスクの中身 | **不良ディスク自体から読んでコピー**。読めなかった部分だけ残りのディスクのパリティから計算 | **残りのディスクのパリティから計算**。不良ディスクは読まない |
| 作業中の冗長性 | ある | **無い**（縮退状態） |

- RAID5 にはチェックサムが無い。不良ディスクが**エラーを出さずに誤った内容を返す**と（書き込みを受け付けたのに
  ハングやリセットで書けていなかった、など）、「交換」はそれをそのまま新しいディスクにコピーする。
  パリティ側は正しい内容で更新されているので、リビルドなら正しい内容が復元される
- md（RAID）は**読み込みエラーではディスクを切り離さない**（パリティから直して書き戻す）。
  そのため、読めないセクタを出し続けるディスクが RAID に残り続け、**ホットスペアも働かない**
- DSM の SMART 判定（OK / NG）は、Uncorrectable が増え続けても「OK」のままだった。生の値の増加で判断する
- **不良ディスクが残ったまま RAID のデータスクラブ（パリティの整合性チェック）をかけない。**
  不一致はパリティを書き直して解消されるので、不良ディスクの誤った内容が正として固定されうる

## 1. 状況の確認

### 1-1. どのディスクが悪いか

- grafana-onp の「Synology ディスク健全性」で、SMART の表の「24h の増加」と、故障系 SMART 値の推移を見る
- NAS に SSH して dmesg を見る（sudo 不要）

  ```bash
  dmesg | grep -E "UNC|exception Emask|hard resetting link|failed command" | tail -50
  cat /proc/mdstat
  ```

  `ata8 (slot 5): ... error: { UNC }` のように、物理スロット番号が出る

- SMART の生の値は sudo なしで読める

  ```bash
  cat /run/synostorage/disks/sata4/smart_info_list.cache   # sataN ごと
  cat /run/synostorage/disks/sata4/serial
  ```

### 1-2. ほかのディスクが健全か

**リビルド中は冗長性が無いので、ほかのディスクが 1 台でも怪しいなら「2-B」を選ぶ。**

- 「Synology ディスク健全性」の SMART の表で、ほかのディスクの再割当・Uncorrectable・Command Timeout が 0 で、24h の増加も 0 であること
- `/proc/mdstat` で、ストレージプール（md2）がすでに縮退していないこと

### 1-3. バックアップの確保

不良ディスクが出ている間に書かれたデータは、すでに壊れている可能性がある。交換の前に、壊れる前の世代を残す。

- PBS: 直近の mcserver / garage / VM のバックアップのうち、**不良の兆候が出る前の世代**を protected にする
  （`proxmox-backup-debug api set /admin/datastore/<ds>/protected --backup-type <host|vm> --backup-id <id> --backup-time <epoch> --protected true`）
- mariadb のダンプ: Garage の `database--{name}/` は DB ごとに最新 14 件しか残らない。同じく兆候の前の世代を別 prefix に退避する
  （[ロールバックの Runbook](./rollback-mcserver-and-mariadb.md) の手順 0a）

## 2-A. 不良ディスクを無効化してリビルドする（ほかのディスクが健全な場合。こちらを優先）

1. 作業時間帯を選ぶ: 日次バックアップ（04:00）と kured の再起動（05:00〜07:00）を避ける。リビルド中は I/O が重くなる
2. DSM の **ストレージマネージャー → HDD/SSD** で不良ディスクを選び、**「無効化」**（Deactivate）する
   - ストレージプールが縮退し、**ホットスペアがあれば自動でリビルドが始まる**
   - ホットスペアが無い場合は、新しいディスクを挿してからストレージプールの「修復」を実行する
3. リビルドの進み具合を確認する

   ```bash
   cat /proc/mdstat    # recovery = xx.x% の行
   ```

4. リビルドが終わったら（`[UUUUU]`）、無効化したディスクを物理的に抜く
5. 新しく入れたディスクの書き込みキャッシュを無効にする（HDD/SSD → ドライブ → 設定）。
   dmesg に `Write cache: disabled` が出ることを確認する
6. ホットスペアを使った場合は、新しいディスクを挿してホットスペアに設定し直す
   （ストレージマネージャー → ホットスペア）。grafana-onp で `raidHotspareCnt` が 1 に戻ることを確認する

## 2-B. 「ドライブの交換」で入れ替える（ほかのディスクも怪しい場合）

縮退中に 2 台目が壊れるとプールごと失うので、冗長性を保ったまま入れ替える。
不良ディスクの誤った内容がコピーされうることを前提に、終わった後に必ず 3 で被害を確認する。

1. 新しいディスクを空きスロットに挿す
2. DSM の **ストレージマネージャー → ストレージプール → 「ドライブの交換」** で、不良ディスクと新しいディスクを選ぶ
3. 完了後、不良ディスクを抜き、書き込みキャッシュの無効化・ホットスペアの設定は 2-A の 5〜6 と同じ

## 3. k8s 側での確認（どちらの場合も必須）

RAID の層では誤った内容に気付けないので、チェックサムを持つ k8s 側の BTRFS で全データを読んで確認する。

1. `synology-iscsi-storage` の全 PV について、マウントしているノードとデバイスを調べる

   ```bash
   kubectl get pv -o custom-columns=PV:.metadata.name,SC:.spec.storageClassName,CLAIM:.spec.claimRef.name | grep synology
   kubectl get volumeattachment | grep <pv>
   # ノードで: findmnt -rn -o SOURCE,TARGET | grep <pv>
   ```

2. ノードで読み取り専用のスクラブをかける（速度を制限する）

   ```bash
   sudo btrfs scrub limit -a -l 100M <mountpoint>
   sudo btrfs scrub start -B -r -d <mountpoint>
   sudo btrfs scrub limit -a -l 0 <mountpoint>
   # 壊れたファイルの特定
   sudo journalctl -k --since "<開始時刻>" | grep -E "checksum error|csum failed" | grep -oE "path: [^)]+" | sort | uniq -c
   ```

   - NAS の load が高いとき（20 超）や、スクラブ中に iSCSI の切断（`detected conn error`）が出たら中断する
   - mariadb のボリュームは、O_DIRECT の影響で NAS と無関係な不一致が出ることがある（#6650）。交換の前後で書かれた時刻を確認して切り分ける

3. 破損が見つかったら、壊れる前の世代から戻す（[ロールバックの Runbook](./rollback-mcserver-and-mariadb.md)）。
   プレイヤーはサーバー間でアイテムを移動できるので、Minecraft は全サーバーと `seichiassist` を同じ時点に揃えて戻す

## 4. 後片付け

- 1-3 で protected にした PBS の世代の保護を解除する。退避した mariadb のダンプの prefix を削除する
- 抜いたディスクは再利用しない。手放す前にデータを消す（認識しない場合は物理的に破壊する）

## 関連

- 障害報告: #6653（2026-10 の SanDisk SSD の故障と、交換によるデータ破損）
- [Minecraftワールド・MariaDBロールバック](./rollback-mcserver-and-mariadb.md)
- mariadb の BTRFS のチェックサム不一致: #6650
