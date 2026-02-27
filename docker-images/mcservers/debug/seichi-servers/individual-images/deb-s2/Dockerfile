FROM ghcr.io/giganticminecraft/seichi_minecraft_server_debug_base_1_18_2:1.0.0@sha256:dcba0efa26923b43ecc9499ea96bf7ef972279cc3bd9fd58d3eac6c0df1cd975

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

# サーバー自体の設定ファイル
COPY --link ./common-minecraft-server-configs /config

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="1057363669803085904"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="1057363486944014468"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="2"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="deb-s2"
