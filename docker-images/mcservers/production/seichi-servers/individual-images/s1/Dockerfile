FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:6520d1f928421638b33920b0a2dbee2c9ab1fd2a4ba4c8d56c369a07cbb12dd1

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /additional-plugins

###
# 環境変数として指定されるべきプラグインの設定
#
ENV CFG_REPLACEMENT__DYNMAP_WEBPAGE_TITLE="アルカディアサーバマップ - ギガンティック☆整地鯖"

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME="s1"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="1"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="s1"

ENV CFG_REPLACEMENT__LITEBANS_SERVER_NAME="s1"
