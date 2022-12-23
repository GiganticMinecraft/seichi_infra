##---
# JVM exporter をダウンロードする stage
FROM ubuntu:22.10 as jmx-prometheus-exporter-downloader

RUN apt-get update \
 && apt-get install -y wget ca-certificates \
 && apt-get clean

RUN wget \
  https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.17.2/jmx_prometheus_javaagent-0.17.2.jar \
  /root/jmx_prometheus_javaagent.jar

# ---
##---
# base image
FROM itzg/minecraft-server:2022.12.0-java8-jdk

# JMX exporter と設定ファイルをイメージに移す
COPY --from jmx-prometheus-exporter-downloader /root/jmx_prometheus_javaagent.jar /jmx-exporter/jmx_prometheus_javaagent.jar
COPY ./jmx-exporter-config.yaml /jmx-exporter/jmx-exporter-config.yaml

##---
# サーバー群に共通する環境変数
#   必要であれば各サーバーの image が (ENV を各々定義することによって) オーバーライドすべき

ENV TYPE="PAPER"

# JVM_OPTS で JMX exporter を Java Agent として利用するよう指定する
ENV JVM_OPTS="-javaagent:/jmx-exporter/jmx_prometheus_javaagent.jar=18321:/jmx-exporter/jmx-exporter-config.yaml"

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
# ---

# サーバー自体の設定ファイル
COPY ./minecraft-server-configs /config
