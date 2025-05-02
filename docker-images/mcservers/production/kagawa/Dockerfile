FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java8-jdk@sha256:87432c16be3b67cbd1190d725f061f81e1507286e16142a8cfcdcc0b9ddf00ef

ENV VERSION="1.16.5"

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="959300037844799560"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="689841701333893163"
