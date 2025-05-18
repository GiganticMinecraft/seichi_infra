FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:6520d1f928421638b33920b0a2dbee2c9ab1fd2a4ba4c8d56c369a07cbb12dd1

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /data/plugins

COPY --link ./custom-minecraft-server-configs /config

###
# 環境変数として指定されるべきプラグインの設定
#
ENV CFG_REPLACEMENT__DYNMAP_WEBPAGE_TITLE="公共施設鯖マップ - ギガンティック☆整地鯖"

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME="s7"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="7"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="s7"

ENV CFG_REPLACEMENT__LITEBANS_SERVER_NAME="s7"
