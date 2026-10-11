FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:a8c5845895442736e3b6a0b19f5cfb07865d34733a361e139fa641df63ce1214

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
