FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java21-jdk@sha256:71b639b2d8da92cc189db9ebbeca265a876fef0f51f0c985cd0e9c2d7e3bfc71

ENV VERSION="1.21.4"
ENV DIFFICULTY="normal"

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="689106486944989232"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="689106759851180044"
