FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:f4e0d18cc15e957a8d32c1d84c2c468c7426ef1a5d3c6c0f77b3aa182bfa22f9

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
