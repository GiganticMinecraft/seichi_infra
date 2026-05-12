FROM ghcr.io/giganticminecraft/seichi_minecraft_server_debug_base_1_18_2:1.0.0@sha256:be8cefedb926eedb9587644b3da61ee41b298a507929ff9a7d0c0efeed06d5e3

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

# サーバー自体の設定ファイル
COPY --link ./common-minecraft-server-configs /config

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="1057363669803085904"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="1057363486944014468"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="2"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="deb-s2"
