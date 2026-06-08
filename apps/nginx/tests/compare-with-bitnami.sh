#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

bitnami_image="${1:-docker.io/bitnami/nginx:latest}"
niceos_image="${2:-docker.io/niceos/nginx:1.31.1-niceos13-r1}"
runtime="${CONTAINER_RUNTIME:-podman}"

inspect_contract() {
  local image="$1"
  "$runtime" image inspect "$image" --format 'User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}} Cmd={{json .Config.Cmd}} Workdir={{.Config.WorkingDir}} ExposedPorts={{json .Config.ExposedPorts}}' || true
}

echo "==> Bitnami image contract"
inspect_contract "$bitnami_image"

echo "==> NiceOS image contract"
inspect_contract "$niceos_image"

echo "==> NiceOS runtime paths"
"$runtime" run --rm "$niceos_image" /bin/bash -lc '
set -euo pipefail
printf "nginx: "; command -v nginx
printf "entrypoint: "; test -x /opt/bitnami/scripts/nginx/entrypoint.sh && echo OK
printf "run: "; test -x /opt/bitnami/scripts/nginx/run.sh && echo OK
printf "conf: "; test -f /opt/bitnami/nginx/conf/nginx.conf && echo OK
'
