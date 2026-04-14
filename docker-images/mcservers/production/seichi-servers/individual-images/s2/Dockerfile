FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:4f28e7d86009bef8351ee4df14d1d5286fd0c467cf2a65f106f5f4c7e4be5a68

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
