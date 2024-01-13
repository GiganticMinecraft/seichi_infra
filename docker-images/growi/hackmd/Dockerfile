# syntax=docker/dockerfile:1.6
FROM hackmdio/hackmd:1.3.0-alpine
LABEL org.opencontainers.image.authors="outductor <inductor.kela+seichi@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/GiganticMinecraft/seichi_infra"
LABEL org.opencontainers.image.source="https://github.com/GiganticMinecraft/seichi_infra/blob/main/docker-images/growi/hackmd/Dockerfile"

# copy script to apply GROWI agent
COPY apply-growi-agent.sh /codimd/apply-growi-agent.sh
# run the script
RUN /codimd/apply-growi-agent.sh

# overwrite HackMD config file
RUN rm -f /files/config.json && rm -f /codimd/config.json
COPY config.json /files/
RUN ln -s /files/config.json /codimd/config.json

# create sqlite data dir
RUN mkdir /files/sqlite && chown codimd /files/sqlite
RUN ln -s /files/sqlite /codimd/sqlite
