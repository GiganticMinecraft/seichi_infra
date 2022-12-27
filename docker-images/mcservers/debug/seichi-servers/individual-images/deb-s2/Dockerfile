FROM ghcr.io/giganticminecraft/seichi_minecraft_server_debug_base_1_12_2@sha256:b24cb39ba0fd9502339f6bc5985ff1e6e29b61857fe8fd2dcb607bae07b9fdda

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
