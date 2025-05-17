FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:a8d98659d759083ea7c9b204e71153c0505041045d2ef34a0b752aff987e29f4

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /data/plugins

###
# 環境変数として指定されるべきプラグインの設定
#
ENV CFG_REPLACEMENT__DYNMAP_WEBPAGE_TITLE="アルカディアサーバマップ - ギガンティック☆整地鯖"

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME="s1"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="1"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="s1"

ENV CFG_REPLACEMENT__LITEBANS_SERVER_NAME="s1"
