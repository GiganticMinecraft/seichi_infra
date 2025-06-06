FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:d64077ebd26db62268148051ed15c00bf2e990e1c1fd73a5f38481f5efe58158

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
