# syntax=docker/dockerfile:1

# Argo Workflows のバックアップ/リストア用イメージ。
#
# 以前は各ワークフローが実行時に download.proxmox.com / enterprise.proxmox.com から
# proxmox-backup-client を apt install していたが、Proxmox の GeoDNS が疎通しない CDN
# ノード (sg2.cdn.proxmox.com = 117.120.5.0/24, 2400:ed00:3::/64) を一定確率で返すため、
# バックアップが確率的に失敗していた (garage のバックアップで 51/185 = 27.6% が失敗)。
# 依存をイメージに焼き込むことで、実行時に Proxmox の CDN へ触れないようにする。

# AWS CLI v2 は self-contained bundle (専用の Python 同梱) なので、
# builder で展開して成果物だけを最終イメージに持ち込む。
FROM mirror.gcr.io/debian:13 AS awscli-builder

# renovate: datasource=github-releases depName=aws/aws-cli
ARG AWSCLI_VERSION=2.36.34

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    set -eux; \
    printf 'Acquire::Retries "8";\nAcquire::ForceIPv4 "true";\n' > /etc/apt/apt.conf.d/99-retries; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl unzip; \
    # curl の --retry は使わない。curl は 1 プロセス内で名前解決をキャッシュするため、
    # --retry では同じ IP を引き続けてしまう (Debian の curl は名前解決キャッシュを
    # 無効化する --dns-cache-timeout を持たない)。プロセスごと起動し直すことで
    # 毎回 DNS を引き直し、別の CDN ノードに当たる機会を作る。
    for i in 1 2 3 4 5 6 7 8; do \
      curl -fsSL --connect-timeout 10 --max-time 300 \
        "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" \
        -o /tmp/awscliv2.zip && break; \
      echo "retry ${i}: awscli download"; \
      sleep 3; \
    done; \
    # for ループの失敗は set -e で拾えないので、成果物の有無で明示的に検証する
    test -s /tmp/awscliv2.zip; \
    unzip -q /tmp/awscliv2.zip -d /tmp; \
    /tmp/aws/install; \
    rm -rf /tmp/awscliv2.zip /tmp/aws

FROM mirror.gcr.io/debian:13

LABEL org.opencontainers.image.authors="outductor <inductor.kela+seichi@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/GiganticMinecraft/seichi_infra"
LABEL org.opencontainers.image.source="https://github.com/GiganticMinecraft/seichi_infra/blob/main/docker-images/pbs-client/Dockerfile"
LABEL org.opencontainers.image.description="proxmox-backup-client, AWS CLI v2, zstd, python3 を同梱した Argo Workflows のバックアップ/リストア用イメージ"

# renovate: datasource=deb depName=proxmox-backup-client
ARG PBS_CLIENT_VERSION=4.2.5-1

# ビルド時は Proxmox の CDN に触れざるを得ないため、リトライを厚くしておく。
# ここでコケても CI を再実行すれば済み、バックアップ本番には影響しない。
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    set -eux; \
    printf 'Acquire::Retries "8";\nAcquire::ForceIPv4 "true";\n' > /etc/apt/apt.conf.d/99-retries; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl; \
    # 死んだ CDN ノードを掴んだときに別ノードを引き直せるよう、プロセスごとリトライする
    # (理由は awscli-builder ステージのコメントを参照)
    for i in 1 2 3 4 5 6 7 8; do \
      curl -fsSL --connect-timeout 10 --max-time 120 \
        https://enterprise.proxmox.com/debian/proxmox-release-trixie.gpg \
        -o /etc/apt/trusted.gpg.d/proxmox-release-trixie.gpg && break; \
      echo "retry ${i}: proxmox release key"; \
      sleep 3; \
    done; \
    test -s /etc/apt/trusted.gpg.d/proxmox-release-trixie.gpg; \
    echo "deb http://download.proxmox.com/debian/pbs-client trixie main" \
      > /etc/apt/sources.list.d/pbs-client.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      "proxmox-backup-client=${PBS_CLIENT_VERSION}" \
      python3 \
      zstd

# /usr/local/bin/aws は bundle 内へのシンボリックリンクであり、COPY するとリンクが
# 解決されて実体がコピーされてしまう。すると PyInstaller 製の aws が自分の隣
# (/usr/local/bin) に libpython を探しに行って起動できなくなるため、bundle 本体だけを
# 持ち込んでリンクは張り直す。
COPY --link --from=awscli-builder /usr/local/aws-cli /usr/local/aws-cli
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws

# ワークフローは script テンプレートから /bin/sh を明示的に呼ぶが、
# 単体で docker run したときに壊れて見えないようにしておく
CMD ["/bin/sh"]
