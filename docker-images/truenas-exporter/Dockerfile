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
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build -buildvcs=false -ldflags="-s -w" -trimpath -o /truenas-exporter

FROM debian:trixie-slim

LABEL org.opencontainers.image.authors="outductor <inductor.kela+seichi@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/GiganticMinecraft/seichi_infra"
LABEL org.opencontainers.image.source="https://github.com/GiganticMinecraft/seichi_infra/blob/main/docker-images/truenas-exporter/Dockerfile"

COPY --link --from=builder /truenas-exporter /bin/
ENV TRUENAS_HOST=""
ENV TRUENAS_PORT="443"
ENV TRUENAS_API_KEY=""
ENV TRUENAS_TLS_SKIP_VERIFY="false"
ENV LISTEN_ADDR=":9814"
EXPOSE 9814
CMD ["/bin/truenas-exporter"]
