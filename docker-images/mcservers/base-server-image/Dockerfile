# syntax=docker/dockerfile:1
ARG MCSERVER_BASE_IMAGE

##---
# JVM exporter をダウンロードする stage
FROM busybox:1.37.0 AS jmx-prometheus-exporter-downloader
ARG JMX_EXPORTER_VERSION=1.4.0
RUN wget \
  -O /root/jmx_prometheus_javaagent.jar \
  https://github.com/prometheus/jmx_exporter/releases/download/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar

##---
# Pyroscope agent をダウンロードする stage
FROM busybox:1.37.0 AS pyroscope-agent-downloader
ARG PYROSCOPE_VERSION=v2.1.2
RUN wget \
  -O /root/pyroscope.jar \
  https://github.com/grafana/pyroscope-java/releases/download/${PYROSCOPE_VERSION}/pyroscope.jar

##---
# Parca perf-map-agent をダウンロードする stage
# JVMのJITコンパイルされたコードのシンボル情報をParcaに提供するために使用
FROM busybox:1.37.0 AS parca-perf-map-agent-downloader
ARG PERF_MAP_AGENT_VERSION=v0.0.2
RUN wget \
  -O /root/perf-map-agent.tar.gz \
  https://github.com/parca-dev/perf-map-agent/releases/download/${PERF_MAP_AGENT_VERSION}/perf-map-agent-x86_64.tar.gz && \
  tar -xzf /root/perf-map-agent.tar.gz -C /root && \
  mv /root/out/amd64/libperfmap.so /root/libperfmap.so

##---
# 最終 stage
#
# MCSERVER_BASE_IMAGE は、 build args を通して
#   itzg/minecraft-server の特定のタグを指定することを想定している
FROM ${MCSERVER_BASE_IMAGE}

# JMX exporter と設定ファイルをイメージに移す
COPY --link --from=jmx-prometheus-exporter-downloader /root/jmx_prometheus_javaagent.jar /jmx-exporter/jmx_prometheus_javaagent.jar
COPY --link ./jmx-exporter-config.yaml /jmx-exporter/jmx-exporter-config.yaml

# Pyroscope agent をイメージに移す
COPY --link --from=pyroscope-agent-downloader /root/pyroscope.jar /pyroscope/pyroscope.jar

# Parca perf-map-agent をイメージに移す
COPY --link --from=parca-perf-map-agent-downloader /root/libperfmap.so /parca/libperfmap.so

# ---
# サーバー群に共通する環境変数
#   必要であれば各サーバーの image が (ENV を各々定義することによって) オーバーライドすべき

ENV TYPE="PAPER"

# JVM_OPTS で JMX exporter と Parca perf-map-agent を Java Agent として利用するよう指定する
# -XX:+PreserveFramePointer: フレームポインタを保持してプロファイリングを有効化
# -agentpath: Parca用のperf-map-agentを読み込み、JITコンパイルされたコードのシンボル情報を提供
ENV JVM_OPTS="-javaagent:/jmx-exporter/jmx_prometheus_javaagent.jar=18321:/jmx-exporter/jmx-exporter-config.yaml -XX:+PreserveFramePointer -agentpath:/parca/libperfmap.so"

# TODO: 2025/10/9 SIGSEGVが発生する問題があるため、一旦コメントアウト
#
# Pyroscope agent の設定
# JAVA_TOOL_OPTIONS は JVM_OPTS とは独立して適用される
# ENV JAVA_TOOL_OPTIONS="-javaagent:/pyroscope/pyroscope.jar -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints"

# Pyroscope 設定（環境変数で管理）
ENV PYROSCOPE_SERVER_ADDRESS="http://pyroscope.monitoring:4040"
ENV PYROSCOPE_FORMAT="jfr"
ENV PYROSCOPE_PROFILING_INTERVAL="10ms"
ENV PYROSCOPE_PROFILER_EVENT="cpu"
ENV PYROSCOPE_PROFILER_ALLOC="512k"
ENV PYROSCOPE_PROFILER_LOCK="10ms"

# Pyroscope のアプリケーション名とラベルは各サーバーで設定される
ENV PYROSCOPE_APPLICATION_NAME=""
ENV PYROSCOPE_LABELS=""

# 設定ファイル内の ${CFG_REPLACEMENT__*} の形をした部分を置き換えるようにする
#   https://github.com/itzg/docker-minecraft-server/tree/9458005b5bd78b8139e13e66c29a449a12dd6218#replacing-variables-inside-configs
ENV REPLACE_ENV_VARIABLE_PREFIX="CFG_REPLACEMENT__"

# /config を /data (サーバーディレクトリ) にコピーするようにする。
#   これによって、 bukkit.yml などを /config に置くことでサーバーに利用させることができるようになる。
#   https://github.com/itzg/docker-minecraft-server/tree/9458005b5bd78b8139e13e66c29a449a12dd6218#optional-plugins-mods-and-config-attach-points
ENV COPY_CONFIG_DEST="/data"
ENV SYNC_SKIP_NEWER_IN_DESTINATION="false"

# /data (サーバーディレクトリ) 内の plugins ディレクトリにあるプラグインを
#   起動前に削除してからコピーするようにする。
# プラグインファイルは (設定ファイルとともに) /plugins からファイルがコピーされるため、
#   `MOD` 環境変数や `SPIGET_RESOURCES` で自動ダウンロードができないプラグインは
#   何らかの手段によって /plugins ディレクトリ直下にマウントすると良い。
ENV REMOVE_OLD_MODS="true"

ENV TZ="Asia/Tokyo"

# サーバー自体の設定ファイル
COPY --link ./common-minecraft-server-configs /config

# プラグインの設定ファイル
COPY --link ./common-plugin-configs /plugins

# 環境変数として指定されるべきプラグインの設定
ENV CFG_REPLACEMENT__DISCORDSRV_TOKEN=""
ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID=""
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID=""
