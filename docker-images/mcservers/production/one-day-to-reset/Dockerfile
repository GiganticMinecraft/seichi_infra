FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java21-jdk@sha256:4ec3034b3c71a347bc6b9a488a4356be39542a32f7e1ab9bceb327d2195b59cb

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
