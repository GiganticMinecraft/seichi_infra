FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java8-jdk@sha256:ada88be0f227d60e0ec27666d08221ddb91010fc3fb316a20fe8c34ca042d319

ENV VERSION="1.16.5"

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="959300037844799560"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="689841701333893163"
