#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

image="${1:-docker.io/niceos/nginx:1.31.1-niceos13-r1}"
runtime="${CONTAINER_RUNTIME:-podman}"

info() { printf '==> %s
' "$*"; }
fail() { printf 'ERROR: %s
' "$*" >&2; exit 1; }

info "basic metadata and command checks: $image"
"$runtime" run --rm "$image" /bin/bash -lc '
set -euo pipefail
test "$BITNAMI_APP_NAME" = "nginx"
test "$BITNAMI_ROOT_DIR" = "/opt/bitnami"
test "$BITNAMI_VOLUME_DIR" = "/bitnami"
test "$NGINX_HTTP_PORT_NUMBER" = "8080"
test "$NGINX_HTTPS_PORT_NUMBER" = "8443"
test "$(command -v nginx)" = "/opt/bitnami/nginx/sbin/nginx"
nginx -v 2>&1 | grep -E "nginx/|nginx version"
nginx -t -c /opt/bitnami/nginx/conf/nginx.conf
printf OK

'

cid=""
cleanup() {
  if [ -n "$cid" ]; then "$runtime" rm -f "$cid" >/dev/null 2>&1 || true; fi
}
trap cleanup EXIT

info "HTTP serving check"
cid="$($runtime run -d --rm -p 18080:8080 "$image")"
for i in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:18080/ >/tmp/niceos-nginx-smoke.html 2>/dev/null; then
    grep -q "NiceOS NGINX" /tmp/niceos-nginx-smoke.html || fail "unexpected HTTP body"
    info "OK"
    exit 0
  fi
  sleep 1
done
fail "nginx did not become reachable on port 18080"
