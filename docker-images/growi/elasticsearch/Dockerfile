# syntax=docker/dockerfile:1.7
ARG version=8.14.1
FROM docker.elastic.co/elasticsearch/elasticsearch:${version}
LABEL org.opencontainers.image.authors="outductor <inductor.kela+seichi@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/GiganticMinecraft/seichi_infra"
LABEL org.opencontainers.image.source="https://github.com/GiganticMinecraft/seichi_infra/blob/main/docker-images/growi/elasticsearch/Dockerfile"

RUN bin/elasticsearch-plugin install analysis-kuromoji
RUN bin/elasticsearch-plugin install analysis-icu
