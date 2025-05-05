FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:sha-e7dd476@sha256:aa81f4a7e51f800283bf7870982e910f4e077f29888df30ea2ddff82df1c8c28

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /data/plugins

COPY --link ./custom-minecraft-server-configs /config

###
# 環境変数として指定されるべきプラグインの設定
#
ENV CFG_REPLACEMENT__DYNMAP_WEBPAGE_TITLE="公共施設鯖マップ - ギガンティック☆整地鯖"

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME="s7"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="7"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="s7"

ENV CFG_REPLACEMENT__LITEBANS_SERVER_NAME="s7"
