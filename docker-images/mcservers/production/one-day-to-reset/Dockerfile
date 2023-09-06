FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java17-jdk@sha256:38b7aec4ee1760f26ae4c11f91d6b93c2af135a1cd4fc0398de2d651071ca078

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
