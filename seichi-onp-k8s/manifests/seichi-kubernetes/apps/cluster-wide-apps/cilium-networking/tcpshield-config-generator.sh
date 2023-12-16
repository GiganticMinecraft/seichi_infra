#!/bin/bash

TCPSHIELD_IP_LIST=$(curl -Ss https://tcpshield.com/v4/)

cat <<EOF > _generated-config.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow--from-tcpshield--to-bungeecord-hogehoge
  namespace: hogehoge-namespace
spec:
  endpointSelector:
    matchLabels:
      app: bungeecord
EOF

for cidr in $TCPSHIELD_IP_LIST
do
  cat <<EOF >> _generated-config.yaml
    - fromCIDRSet:
        - cidr: "$cidr"
      toPorts:
        - ports:
            - port: "25565"
EOF

done
