# syntax=docker/dockerfile:1
FROM golang:1.26-trixie AS builder
# Build
ARG GOOS=linux
ARG GOARCH=amd64
WORKDIR /go/src

RUN --mount=type=cache,target=/go/pkg/mod/,sharing=locked \
    --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    go mod download -x
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build -buildvcs=false -ldflags="-s -w" -trimpath -o /mod-downloader

FROM debian:trixie-slim

LABEL org.opencontainers.image.authors="outductor <inductor.kela+seichi@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/GiganticMinecraft/seichi_infra"
LABEL org.opencontainers.image.source="https://github.com/GiganticMinecraft/seichi_infra/blob/main/docker-images/mod-downloader/Dockerfile"

COPY --link --from=builder /mod-downloader /bin/
ENV S3_ENDPOINT=""
ENV S3_ACCESS_KEY=""
ENV S3_SECRET_KEY=""
ENV S3_REGION="seichi-cloud"
ENV BUCKET_NAME=""
ENV BUCKET_PREFIX_NAME=""
ENV DOWNLOAD_TARGET_DIR_PATH=""
CMD ["/bin/mod-downloader"]
