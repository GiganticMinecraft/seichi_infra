FROM golang:1.20-bullseye as builder
WORKDIR /go/src
COPY --link go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download
COPY --link . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o /mod-downloader

FROM gcr.io/distroless/static:nonroot

COPY --from=builder --chown=nonroot:nonroot /mod-downloader /bin/
ENV MINIO_ENDPOINT=""
ENV MINIO_ACCESS_KEY=""
ENV MINIO_ACCESS_SECRET=""
ENV BUCKET_NAME=""
ENV BUCKET_PREFIX_NAME=""
ENV DOWNLOAD_TARGET_DIR_PATH=""
CMD ["/bin/mod-downloader"]
