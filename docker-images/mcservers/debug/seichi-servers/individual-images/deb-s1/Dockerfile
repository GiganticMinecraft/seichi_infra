FROM ghcr.io/giganticminecraft/seichi_minecraft_server_debug_base_1_18_2:1.0.0@sha256:77bcd4ea83e03c028825ef3a9effb3225fb45f59b0cfe2e0d6fdb65c7808d0c4

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

# サーバー自体の設定ファイル
COPY --link ./common-minecraft-server-configs /config

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="1054159992447570032"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="1054159676964622426"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="1"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="deb-s1"
