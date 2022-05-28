#!/bin/bash
set -eu

# hack: to_entries でオブジェクトを配列にバラして、
#       各要素を base64 でエンコードすることで for で回せるようにする
#       参考: https://www.starkandwayne.com/blog/bash-for-loop-over-json-array-using-jq/
kv_pairs="$(echo "${SECRETS_CONTEXT}" | jq -r 'to_entries | .[] | @base64')"

for key_value_pair_json_in_base64 in $kv_pairs; do
  # kv_pairs の各要素は base64 エンコードされた
  # { "key": **, "value": ** } の形式の json なので、decode
  key_value_pair_json="$(echo "${key_value_pair_json_in_base64}" | base64 -d)"

  # key / value の組を読む
  key="$(echo "${key_value_pair_json}" | jq -r '.key')"
  value="$(echo "${key_value_pair_json}" | jq -r '.value')"

  # TF_VAR_${tf_v_name} で始まる secret variable のみ、tf_v_name の部分を小文字にして環境変数に export する。
  # Terraform 側では variable は小文字で宣言されており、secrets オブジェクトは全部大文字で入れてくるため、
  # このような変換をする必要がある。
  # 参考: https://stackoverflow.com/a/2172367
  if [[ $key == TF_VAR_* ]]; then
    # prefix を除去
    # 参考: https://stackoverflow.com/a/16623897
    tf_variable_secret_name="${key#TF_VAR_}"

    tf_variable_name="$(echo "$tf_variable_secret_name" | tr '[:upper:]' '[:lower:]')"

    # 参考: https://stackoverflow.com/a/68008861
    echo "TF_VAR_${tf_variable_name}=${value}" >> $GITHUB_ENV
  fi
done
