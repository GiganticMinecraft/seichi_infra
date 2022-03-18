# seichi-onp-network-iap

## セットアップ

以下の手順に従って `seichi-onp-network-iap` となるサーバーに `setup-server.sh` を実行させてください。`2` の操作は、 `setup-server.sh` が更新されるたびに行ってください。

1. `~/.ssh/config` に、 "seichi-onp-network-iap" という名前の接続先情報を追加する

    ```
    Host seichi-onp-network-iap
        HostName 192.168.3.22
        User cloudinit
        Port 22
    ```

    "seichi-onp-network-iap" という名前が利用不可能な場合は別の名前を使ったうえで、次のステップで `ssh` 先を書き換えるようにしてください。

2. `seichi-onp-network-iap` にスクリプトを実行させる

    ```bash
    ssh seichi-onp-network-iap -t 'bash <(wget -qO- https://raw.githubusercontent.com/GiganticMinecraft/seichi_infra/main/seichi-onp-network-iap/setup-server.sh)'
    ```

3. 再起動後、 `cloudflared` の認証を通してください。

    ```bash
    ssh seichi-onp-network-iap -t 'sudo docker ps --format "{{.ID}}" | while read -r cid ; do sudo docker logs $cid | less ; done'
    ```

   で各コンテナのログを見て、Cloudflareの認証用のURLがあればそれで認証してください。認証が終わった後は、 `q` で次のコンテナのログに移動できます。
