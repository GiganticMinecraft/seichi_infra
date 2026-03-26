# 整地鯖管理者が、デバッグ目的などで内部的なサービスに接続する必要がある際に経由するネットワーク。
# NOTE: Certificate Pack は Cloudflare 側で自動管理されているため、Terraform 管理外としています。
#
# NOTE: Cloudflare provider v4 → v5 移行のため、旧リソース定義は cloudflare_v4_state_cleanup.tf の
# removed ブロックに移行しました。v5 移行 PR で新リソースタイプとして再定義されます。
