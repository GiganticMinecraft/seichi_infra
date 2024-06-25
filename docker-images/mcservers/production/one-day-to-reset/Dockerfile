FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java17-jdk@sha256:9c660fe143fa536baffa32ba71cc1403d2ff5a9671d128deaacba7768f5c5e90

ENV VERSION="1.20.1"
ENV DIFFICULTY="normal"

# プラグインリスト
#   このイメージでは基底のリスト (/extras/plugin-list.ini) に追記する
COPY --link ./additional-plugin-list.ini /extras/additional-plugin-list.ini
RUN /bin/bash -c "cat /extras/additional-plugin-list.ini >> /extras/plugin-list.ini"

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="689106486944989232"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="689106759851180044"
