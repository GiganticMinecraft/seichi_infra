FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:d9b48a3598083768112c1a77f687afdddbae0664757768eb034df3cb770d99f2

ENV VERSION="1.18.2"
ENV DIFFICULTY="peaceful"

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /data/plugins

###
# 環境変数として指定されるべきプラグインの設定
#

# e.g. "9225"
ENV CFG_REPLACEMENT__PROMETHEUS_EXPORTER_PORT=""

# originally it was "\\192.168.xxx.xxx\seichi-share\schematics"
ENV CFG_REPLACEMENT__WORLDEDIT_SCHEMATICS_DIRECTORY=""

ENV CFG_REPLACEMENT__SEICHIASSIST_DB_HOST=""
ENV CFG_REPLACEMENT__SEICHIASSIST_DB_PORT=""
ENV CFG_REPLACEMENT__SEICHIASSIST_DB_USER=""
ENV CFG_REPLACEMENT__SEICHIASSIST_DB_PASSWORD=""

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="4"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="votelistener"

# Discord のチャットチャンネルへの Webhook
ENV CFG_REPLACEMENT__SEICHIASSIST_URL_WEBHOOK_NOTIFICATION=""

ENV CFG_REPLACEMENT__SEICHIASSIST_REDISBUNGEE_REDIS_HOST=""
ENV CFG_REPLACEMENT__SEICHIASSIST_REDISBUNGEE_REDIS_PORT=""

ENV CFG_REPLACEMENT__SEICHIASSIST_BUNGEESEMAPHORE_RESPONDER_REDIS_HOST=""
ENV CFG_REPLACEMENT__SEICHIASSIST_BUNGEESEMAPHORE_RESPONDER_REDIS_PORT=""

ENV CFG_REPLACEMENT__VOTIFIER_TOKEN_DEFAULT=""
