#!/bin/bash
set -euo pipefail

# terraform plan の結果を PR にコメントする。
# 以前このスクリプトが付けたコメントがあれば、新しく付けずに更新する。
#
# 必要な環境変数:
#   GH_TOKEN   : pull-requests: write を持つトークン
#   PR_NUMBER  : コメント先の PR 番号
#   PLAN_FILE  : terraform plan の出力を保存したファイル
#   RUN_URL    : この workflow run の URL

export LC_ALL=C.UTF-8

readonly marker="<!-- terraform-plan-comment -->"
# PR コメントの上限は 65536 文字なので、見出しなどの分を残して plan を切り詰める
readonly max_plan_chars=60000

plan="$(cat "${PLAN_FILE}")"
summary="$(grep -m1 -E '^(Plan:|No changes\.)' <<< "${plan}" || true)"

if (( ${#plan} > max_plan_chars )); then
  plan="${plan:0:max_plan_chars}
... (長すぎるため省略。全文は実行ログを参照)"
fi

body_file="$(mktemp)"
cat > "${body_file}" <<EOS
${marker}
### Terraform \`plan\` Succeeded

**${summary:-plan の要約行が見つかりませんでした}**

<details><summary>plan の全文</summary>

\`\`\`\`
${plan}
\`\`\`\`

</details>

[実行ログ](${RUN_URL})
EOS

# 同じ PR に以前付けたコメントを探す
comment_id="$(
  gh api --paginate "repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" \
    | jq -r --arg marker "${marker}" \
      '.[] | select(.user.login == "github-actions[bot]" and (.body | startswith($marker))) | .id' \
    | tail -n1
)"

# body を引数で渡すと長い plan で引数長の上限に当たるので、JSON にして標準入力から渡す
if [[ -n "${comment_id}" ]]; then
  jq -n --rawfile body "${body_file}" '{body: $body}' \
    | gh api -X PATCH "repos/${GITHUB_REPOSITORY}/issues/comments/${comment_id}" --input - > /dev/null
  echo "Updated comment ${comment_id}"
else
  jq -n --rawfile body "${body_file}" '{body: $body}' \
    | gh api -X POST "repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" --input - > /dev/null
  echo "Created a new comment"
fi
