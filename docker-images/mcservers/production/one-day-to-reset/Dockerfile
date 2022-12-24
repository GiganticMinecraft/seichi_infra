FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java17-jdk@sha256:c15d413e504394d8002dc93cfb3c6fe282b7ed070b1ddcea5bb2ca5082caeccd

ENV VERSION="1.19.2"
ENV DIFFICULTY="normal"

# プラグインリスト
#   https://github.com/itzg/docker-minecraft-server/tree/ef9318f22e60c210289080561c9042050bb4fc4e#modplugin-url-listing-file
ENV MODS_FILE="/extras/plugin-list.ini"
COPY ./plugin-list.ini /extras/plugin-list.ini

# プラグインの設定ファイル
# 基底イメージに入っている設定ファイルしか利用していないので COPY しない
# COPY ./plugin-configs /plugins

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="689106486944989232"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="689106759851180044"
