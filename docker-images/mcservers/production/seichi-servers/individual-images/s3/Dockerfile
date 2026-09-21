FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:28dfd40b49e24bb10627534edd0bfba19f6692ac692568f002b47c7d096428a0

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
