FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:sha-bc9ee37

ENV VERSION="1.16.5"

# プラグインリスト
#   https://github.com/itzg/docker-minecraft-server/tree/ef9318f22e60c210289080561c9042050bb4fc4e#modplugin-url-listing-file
ENV MODS_FILE="/extras/plugin-list.ini"
COPY ./plugin-list.ini /extras/plugin-list.ini

# プラグインの設定ファイル
COPY ./plugin-configs /plugins

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="959300037844799560"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="689841701333893163"
