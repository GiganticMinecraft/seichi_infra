FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:1.0.0-java8-jdk@sha256:735a2d1823820986339cd97f74c0b19d1342de4b86e426edbc12495930fdfea9

ENV VERSION="1.12.2"

# プラグインリスト
#   このイメージでは基底のリスト (/extras/plugin-list.ini) に追記する
COPY ./additional-plugin-list.ini /extras/additional-plugin-list.ini
RUN /bin/bash -c "cat /extras/additional-plugin-list.ini >> /extras/plugin-list.ini"

# プラグインの設定ファイル
COPY ./additional-plugin-configs /plugins
