FROM ghcr.io/giganticminecraft/seichi_minecraft_server_debug_base_1_12_2@sha256:394a41dc92b194a35128143b12048795855b1dc39fa6f24498ca36343b6284ec

# プラグインリスト
#   このイメージでは基底のリスト (/extras/plugin-list.ini) に追記する
COPY --link ./additional-plugin-list.ini /extras/additional-plugin-list.ini
RUN /bin/bash -c "cat /extras/additional-plugin-list.ini >> /extras/plugin-list.ini"

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="1057363669803085904"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="1057363486944014468"

ENV CFG_REPLACEMENT__DYNMAP_WEBPAGE_TITLE="deb-s2 マップ - ギガンティック☆整地鯖"

ENV CFG_REPLACEMENT__LITEBANS_SERVER_NAME="deb-s2"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="2"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="deb-s2"
