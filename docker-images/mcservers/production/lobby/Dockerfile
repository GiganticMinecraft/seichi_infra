FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java17-jdk@sha256:fb69451efa7f930eeeed583e9900425317600ae66a47570d1ed1aaf13c67a65b

ENV VERSION="1.18.2"
ENV DIFFICULTY="peaceful"

# プラグインリスト
#   このイメージでは基底のリスト (/extras/plugin-list.ini) に追記する
COPY --link ./additional-plugin-list.ini /extras/additional-plugin-list.ini
RUN /bin/bash -c "cat /extras/additional-plugin-list.ini >> /extras/plugin-list.ini"

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /data/plugins

###
# 環境変数として指定されるべきプラグインの設定
#
ENV CFG_REPLACEMENT__COREPROTECT_MYSQL_HOST=""
ENV CFG_REPLACEMENT__COREPROTECT_MYSQL_PORT=""
ENV CFG_REPLACEMENT__COREPROTECT_MYSQL_USER=""
ENV CFG_REPLACEMENT__COREPROTECT_MYSQL_PASSWORD=""

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME=""

# e.g. "9225"
ENV CFG_REPLACEMENT__PROMETHEUS_EXPORTER_PORT=""

# originally it was "\\192.168.xxx.xxx\seichi-share\schematics"
ENV CFG_REPLACEMENT__WORLDEDIT_SCHEMATICS_DIRECTORY=""
