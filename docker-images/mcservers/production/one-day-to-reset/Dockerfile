FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java21-jdk@sha256:e31dc3323b8cd81f316cccb6388cdb03f91f0ab034138fa367d38b1c1a5526e5

ENV VERSION="1.21.1"
ENV DIFFICULTY="normal"

# プラグインリスト
#   このイメージでは基底のリスト (/extras/plugin-list.ini) に追記する
COPY --link ./additional-plugin-list.ini /extras/additional-plugin-list.ini
RUN /bin/bash -c "cat /extras/additional-plugin-list.ini >> /extras/plugin-list.ini"

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="689106486944989232"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="689106759851180044"
