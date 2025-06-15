FROM ghcr.io/giganticminecraft/seichi_minecraft_server_production_common:1.0.0@sha256:cffe40a13c43b09f42e842f4c1bcee0a21fc82906bfc4c59174f0846485a9d89

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

###
# 環境変数として指定されるべきプラグインの設定
#
ENV CFG_REPLACEMENT__DYNMAP_WEBPAGE_TITLE="アルカディアサーバーマップ - ギガンティック☆整地鯖"

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME="s1"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="1"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="s1"

ENV CFG_REPLACEMENT__LITEBANS_SERVER_NAME="s1"
