#!/bin/bash
set -eu

# 第二引数が文字列として第一引数で始まる場合、第一引数の部分を除去する
function strip_prefix () {
  local -r prefix="$1"
  local -r str="$2"

  # 参考: https://stackoverflow.com/a/16623897
  echo "${str#"$prefix"}"
}

# 第二引数が第一引数で始まるかどうかを判定する
function starts_with () {
  local -r prefix="$1"
  local -r str="$2"

  str_without_prefix="$(strip_prefix "${prefix}" "${str}")"

  if [[ "${str}" == "${str_without_prefix}" ]]; then
    return 1
  else
    return 0;
  fi
}

# 第一引数の文字列のどの改行の後にも現れないような delimiter を選ぶ
function pick_delimiter_for () {
  local -r str="$1"

  local -r delimiter_prefix="EOS_"

  local suffix=0
  while true; do
    delimiter_to_try="${delimiter_prefix}${suffix}"

    # delimiter_to_try がいずれかの行の先頭に現れたら suffix をインクリメントしてやり直す
    while read -r line; do
      if starts_with "${delimiter_to_try}" "${line}"; then
        suffix=$((suffix + 1))
        continue 2;
      fi
    done <<< "${str}"

    echo "${delimiter_to_try}"
    return 0
  done
}

# hack: to_entries でオブジェクトを配列にバラして、
#       各要素を base64 でエンコードすることで for で回せるようにする
#       参考: https://www.starkandwayne.com/blog/bash-for-loop-over-json-array-using-jq/
kv_pairs="$(echo "${SECRETS_CONTEXT}" | jq -r 'to_entries | .[] | @base64')"

for key_value_pair_json_in_base64 in $kv_pairs; do
  # kv_pairs の各要素は base64 エンコードされた
  # { "key": **, "value": ** } の形式の json なので、 base64 -d でデコードする
  key_value_pair_json="$(echo "${key_value_pair_json_in_base64}" | base64 -d)"

  # key / value の組を読む
  key="$(echo "${key_value_pair_json}" | jq -r '.key')"
  value="$(echo "${key_value_pair_json}" | jq -r '.value')"

  # TF_VAR_${tf_v_name} で始まる secret variable のみ、tf_v_name の部分を小文字にして環境変数に export する。
  # Terraform 側では variable は小文字で宣言されており、secrets オブジェクトはキーが全部大文字になっているため、
  # このような変換をする必要がある。
  if starts_with "TF_VAR_" "${key}"; then
    tf_variable_secret_name="$(strip_prefix "TF_VAR_" "${key}")"
    tf_variable_name="$(echo "$tf_variable_secret_name" | tr '[:upper:]' '[:lower:]')"

    # {name}<<{delimiter}
    # {value}
    # {delimiter}
    # のような構文でMultilineなenvironment variableを設定できる。
    # 参考: https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#multiline-strings

    delimiter="$(pick_delimiter_for "${value}")"

    echo "TF_VAR_${tf_variable_name}=${delimiter}" >> "$GITHUB_ENV"
    echo "${value}" >> "${GITHUB_ENV}"
    echo "${delimiter}" >> "${GITHUB_ENV}"
  fi
done
