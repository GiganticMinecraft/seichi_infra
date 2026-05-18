FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:f816cf77a74dc3c195dd9665dab77da6f558fccd4475990d1b246f8f65c946fd

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

###
# 環境変数として指定されるべきプラグインの設定
#
ENV CFG_REPLACEMENT__DYNMAP_WEBPAGE_TITLE="ヴァルハラサーバーマップ - ギガンティック☆整地鯖"

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME="s3"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="3"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="s3"

ENV CFG_REPLACEMENT__LITEBANS_SERVER_NAME="s3"
