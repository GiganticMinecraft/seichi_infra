# seichi-authenticator

## セットアップ

以下の手順に従って `seichi-authenticator` となるサーバーに `setup-server.sh` を実行させてください。`2` の操作は、 `setup-server.sh` が更新されるたびに行ってください。

1. `~/.ssh/config` に、 "seichi-authenticator" という名前の接続先情報を追加する

    ```
    Host seichi-authenticator
        HostName 192.168.3.21
        User kory
        Port 22
    ```

    "seichi-authenticator" という名前が利用不可能な場合は別の名前を使ったうえで、次のステップで `ssh` 先を書き換えるようにしてください。

2. `seichi-authenticator` にスクリプトを実行させる

    ```bash
    ssh seichi-authenticator -t 'bash <(wget -qO- https://raw.githubusercontent.com/GiganticMinecraft/seichi_infra/main/seichi-authenticator/setup-server.sh)'
    ```
