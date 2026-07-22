FROM ghcr.io/giganticminecraft/seichi_minecraft_server_debug_base_1_18_2:1.0.0@sha256:8c56bb1feaadba6a15d529bfd04a3096209549070a42735782935127df5b30ae

# このイメージは sha-<git short SHA> タグに加えて、再 push される安定タグ 1.0.0 でも公開される。
# マニフェスト側は 1.0.0@sha256:... で参照し、digest の更新は Renovate が追従する。
# 署名は Kyverno が検証できるレガシー Cosign 形式 (.sig タグ) で行われる。

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

# サーバー自体の設定ファイル
COPY --link ./common-minecraft-server-configs /config

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="1054159992447570032"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="1054159676964622426"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="1"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="deb-s1"
