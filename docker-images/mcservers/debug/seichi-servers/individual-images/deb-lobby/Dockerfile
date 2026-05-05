FROM ghcr.io/giganticminecraft/seichi_minecraft_server_debug_base_1_18_2:1.0.0@sha256:5bb3a75472f47e080e5b63b30ff38e701379c0c6c27c3e9f8af1bb53a80a9b61

COPY --link ./additional-plugin-configs /plugins
COPY --link ./common-minecraft-server-configs /config

ENV DIFFICULTY="peaceful"

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="1501239187376967830"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="1501241212336607294"

ENV CFG_REPLACEMENT__LUCKPERMS_SERVER_NAME="debug-lobby"
