FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:c351d15c6833a70f3f8398b651b6fa7f90abd2d64c2a6699959a86e94d9a9013

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

COPY --link ./custom-minecraft-server-configs /config

###
# 環境変数として指定されるべきプラグインの設定
#
ENV CFG_REPLACEMENT__DYNMAP_WEBPAGE_TITLE="第1整地専用サーバーマップ - ギガンティック☆整地鯖"

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME="s5"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="5"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="s5"

ENV CFG_REPLACEMENT__LITEBANS_SERVER_NAME="s5"
