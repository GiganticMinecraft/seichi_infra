FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:2020afe0da4aef98461ded088c24eb66bf20ea90ea6b20801e75c34e7695296c

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
