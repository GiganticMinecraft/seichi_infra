FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:e322faff3b63551411899375c4381c309f8decbb0dad70700d1699f49d0091f4

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

COPY --link ./custom-minecraft-server-configs /config

###
# 環境変数として指定されるべきプラグインの設定
#
ENV CFG_REPLACEMENT__DYNMAP_WEBPAGE_TITLE="公共施設サーバーマップ - ギガンティック☆整地鯖"

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME="s7"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="7"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="s7"

ENV CFG_REPLACEMENT__LITEBANS_SERVER_NAME="s7"
