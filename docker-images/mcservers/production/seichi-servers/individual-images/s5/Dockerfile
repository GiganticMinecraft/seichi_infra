FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:b831e751085210ad51125d8f3c50b28ad363634d9d18457019cd4626bcff4fe1

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /data/plugins

COPY --link ./custom-minecraft-server-configs /config

###
# 環境変数として指定されるべきプラグインの設定
#
ENV CFG_REPLACEMENT__DYNMAP_WEBPAGE_TITLE="第1整地専用サーバマップ - ギガンティック☆整地鯖"

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME="s5"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="5"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="s5"

ENV CFG_REPLACEMENT__LITEBANS_SERVER_NAME="s5"
