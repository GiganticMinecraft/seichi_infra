FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java21-jdk@sha256:73718b0a157206e268be4a3b1040239fee56c7eb3bbfd250e4b7ccacca38eaff

ENV VERSION="1.21.4"
ENV DIFFICULTY="normal"

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="689106486944989232"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="689106759851180044"
