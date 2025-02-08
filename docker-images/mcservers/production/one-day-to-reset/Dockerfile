FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java21-jdk@sha256:cbc2e87493055ce1e71a0e5c73543ff69c0453c16588f4cdeb285e4a8bef72f3

ENV VERSION="1.21.4"
ENV DIFFICULTY="normal"

# プラグインリスト
#   このイメージでは基底のリスト (/extras/plugin-list.ini) に追記する
COPY --link ./additional-plugin-list.ini /extras/additional-plugin-list.ini
RUN /bin/bash -c "cat /extras/additional-plugin-list.ini >> /extras/plugin-list.ini"

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="689106486944989232"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="689106759851180044"
