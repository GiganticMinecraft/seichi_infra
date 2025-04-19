FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java8-jdk@sha256:78d2a6ee105d13bd85db76ac1a8acae2de09a4ad54a52f46bf09096b65cf3e54

ENV VERSION="1.16.5"

# プラグインリスト
#   このイメージでは基底のリスト (/extras/plugin-list.ini) に追記する
COPY --link ./additional-plugin-list.ini /extras/additional-plugin-list.ini
RUN /bin/bash -c "cat /extras/additional-plugin-list.ini >> /extras/plugin-list.ini"

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="959300037844799560"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="689841701333893163"
