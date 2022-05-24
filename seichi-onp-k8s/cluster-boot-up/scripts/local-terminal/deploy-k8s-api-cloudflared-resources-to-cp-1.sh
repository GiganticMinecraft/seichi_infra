#!/bin/bash

# region manifest URLを生成する
target_branch="$1"
k8s_definition_base_url="https://raw.githubusercontent.com/GiganticMinecraft/seichi_infra/${target_branch}/seichi-onp-k8s"
cloudflared_k8s_endpoint_manifest="${k8s_definition_base_url}/manifests/seichi-kubernetes/apps/cluster-wide-app-resources/cloudflared-k8s-endpoint.yaml"
# endregion

# region secret リソースの中身を生成する
cloudflare_cert_pem="$(/bin/bash <(curl -s "${k8s_definition_base_url}/cluster-boot-up/scripts/local-terminal/obtain-cloudflared-cert.sh.sh") "${target_branch}")"

prerequisite_resources="$(cat <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: test
  labels:
    name: cluster-wide-apps
---
apiVersion: v1
kind: Secret
metadata:
  name: cloudflared-tunnel-credential
  namespace: cluster-wide-apps
type: Opaque
data:
  TUNNEL_CREDENTIAL: "$(echo "${cloudflare_cert_pem}" | base64 -w 0 -)"
EOF
)"
# endregion

prerequisite_resources_apply_cmd="
cat <<EOF | kubectl apply -f -
${prerequisite_resources}
EOF
"

ssh seichi-onp-k8s-cp-1 "${prerequisite_resources_apply_cmd}"
ssh seichi-onp-k8s-cp-1 "kubectl apply -f \"${cloudflared_k8s_endpoint_manifest}\""
