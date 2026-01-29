FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:f14e0d3a9232bfbe20e0c7df46f9fd0e2fdb603f2cca23164ebc7a10d977ebf0

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

###
# 環境変数として指定されるべきプラグインの設定
#
ENV CFG_REPLACEMENT__DYNMAP_WEBPAGE_TITLE="エデンサーバーマップ - ギガンティック☆整地鯖"

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME="s2"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="2"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="s2"

ENV CFG_REPLACEMENT__LITEBANS_SERVER_NAME="s2"
