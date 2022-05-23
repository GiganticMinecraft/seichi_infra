#!/bin/bash
set -e

function pick_free_port () {
  # ref. https://stackoverflow.com/a/35338833
  for i in {10000..65535}; do
    # continue if the port accepts some input
    (exec 2>&- echo > "/dev/tcp/localhost/$i") && continue;

    echo "$i"
    return 0
  done

  # no port is open
  return 1
}


# External Program Protocol
# https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source#external-program-protocol
result=$(cat <<EOF
  {
    "port": "$(pick_free_port)"
  }
EOF
)

echo "$result"
