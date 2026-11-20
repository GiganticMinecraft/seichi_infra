FROM ghcr.io/giganticminecraft/seichi_minecraft_server_debug_base_1_18_2:1.0.0@sha256:ac0f37625640d65649843ee4ce78ea77e4a6c25745bd08fbf5b0f7d120c1abdd

# このイメージは sha-<git short SHA> タグに加えて、再 push される安定タグ 1.0.0 でも公開される。
# マニフェスト側は 1.0.0@sha256:... で参照し、digest の更新は Renovate が追従する。
# 署名は Kyverno が検証できるレガシー Cosign 形式 (.sig タグ) で行われる。

# プラグインの設定ファイル
COPY --link ./additional-plugin-configs /plugins

# サーバー自体の設定ファイル
COPY --link ./common-minecraft-server-configs /config

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="1057363669803085904"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="1057363486944014468"

ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_NUM="2"
ENV CFG_REPLACEMENT__SEICHIASSIST_SERVER_ID="deb-s2"
