FROM golang:1.20-bullseye as builder
# Build
ARG GOOS=linux
ARG GOARCH=amd64
WORKDIR /go/src
COPY --link go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download
COPY --link . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build -buildvcs=false -ldflags="-s -w" -trimpath -o /mod-downloader

FROM debian:bullseye-slim

LABEL org.opencontainers.image.authors="Kohei Ota <kela@inductor.me>"
LABEL org.opencontainers.image.url="https://github.com/GiganticMinecraft/seichi_infra"
LABEL org.opencontainers.image.source="https://github.com/GiganticMinecraft/seichi_infra/blob/main/docker-images/mod-downloader/Dockerfile"

COPY --link --from=builder /mod-downloader /bin/
ENV MINIO_ENDPOINT=""
ENV MINIO_ACCESS_KEY=""
ENV MINIO_ACCESS_SECRET=""
ENV BUCKET_NAME=""
ENV BUCKET_PREFIX_NAME=""
ENV DOWNLOAD_TARGET_DIR_PATH=""
CMD ["/bin/mod-downloader"]
