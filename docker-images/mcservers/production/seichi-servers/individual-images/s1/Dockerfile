FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:1ff9ead7fb1157b217a6fcad829e9373bff3593666db2a5ac8b56a24a89aea5f

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

###
# 環境変数として指定されるべきプラグインの設定
#
ENV CFG_REPLACEMENT__DYNMAP_WEBPAGE_TITLE="アルカディアサーバーマップ - ギガンティック☆整地鯖"

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME="s1"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="1"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="s1"

ENV CFG_REPLACEMENT__LITEBANS_SERVER_NAME="s1"
