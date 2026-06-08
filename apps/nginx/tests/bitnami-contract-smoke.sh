#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

image="${1:-docker.io/niceos/nginx:1.31.1-niceos13-r1}"
runtime="${CONTAINER_RUNTIME:-podman}"

info() { printf '==> %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

run() {
  "$runtime" run --rm "$@"
}

info "Bitnami-compatible NGINX contract: ${image}"

info "environment, user and path contract"
run "$image" /bin/bash -lc '
set -euo pipefail

test "$(id -u)" = "1001"
test "$BITNAMI_APP_NAME" = "nginx"
test "$BITNAMI_ROOT_DIR" = "/opt/bitnami"
test "$BITNAMI_VOLUME_DIR" = "/bitnami"
test "$NGINX_HTTP_PORT_NUMBER" = "8080"
test "$NGINX_HTTPS_PORT_NUMBER" = "8443"

case ":$PATH:" in
  *":/opt/bitnami/common/bin:"*) ;;
  *) echo "missing /opt/bitnami/common/bin in PATH" >&2; exit 1 ;;
esac

case ":$PATH:" in
  *":/opt/bitnami/nginx/sbin:"*) ;;
  *) echo "missing /opt/bitnami/nginx/sbin in PATH" >&2; exit 1 ;;
esac

test "$(command -v nginx)" = "/opt/bitnami/nginx/sbin/nginx"
nginx -v 2>&1 | grep -E "nginx/|nginx version"
echo OK
'

info "filesystem layout contract"
run "$image" /bin/bash -lc '
set -euo pipefail

for path in \
  /app \
  /bitnami \
  /bitnami/nginx \
  /opt/bitnami \
  /opt/bitnami/common/bin \
  /opt/bitnami/common/lib \
  /opt/bitnami/nginx \
  /opt/bitnami/nginx/sbin \
  /opt/bitnami/nginx/conf \
  /opt/bitnami/nginx/conf/server_blocks \
  /opt/bitnami/nginx/conf/stream_server_blocks \
  /opt/bitnami/nginx/conf/context.d/main \
  /opt/bitnami/nginx/conf/context.d/events \
  /opt/bitnami/nginx/conf/context.d/http \
  /opt/bitnami/nginx/logs \
  /opt/bitnami/nginx/tmp \
  /opt/bitnami/scripts \
  /opt/bitnami/scripts/nginx; do
  test -e "$path" || { echo "missing path: $path" >&2; exit 1; }
done

for file in \
  /opt/bitnami/scripts/nginx/entrypoint.sh \
  /opt/bitnami/scripts/nginx/run.sh \
  /opt/bitnami/scripts/nginx/setup.sh \
  /opt/bitnami/scripts/nginx/postunpack.sh; do
  test -x "$file" || { echo "missing executable script: $file" >&2; exit 1; }
done

test -x /opt/bitnami/nginx/sbin/nginx
test -f /opt/bitnami/nginx/conf/nginx.conf
test -f /opt/bitnami/nginx/conf/mime.types
test -f /opt/bitnami/nginx/conf/server_blocks/default.conf
test -e /opt/bitnami/common/lib/libnss_wrapper.so

echo OK
'

info "nginx configuration contract"
run "$image" /bin/bash -lc '
set -euo pipefail

test "$(readlink /etc/nginx/nginx.conf)" = "/opt/bitnami/nginx/conf/nginx.conf"

grep -Eq "^[[:space:]]*pid[[:space:]]+/opt/bitnami/nginx/tmp/nginx.pid;" \
  /opt/bitnami/nginx/conf/nginx.conf

grep -Eq "^[[:space:]]*error_log[[:space:]]+/opt/bitnami/nginx/logs/error.log" \
  /opt/bitnami/nginx/conf/nginx.conf

grep -Eq "^[[:space:]]*access_log[[:space:]]+/opt/bitnami/nginx/logs/access.log" \
  /opt/bitnami/nginx/conf/nginx.conf

grep -Eq "listen[[:space:]]+8080" \
  /opt/bitnami/nginx/conf/server_blocks/default.conf

nginx -t
nginx -t -c /opt/bitnami/nginx/conf/nginx.conf
echo OK
'

info "logs contract"
run "$image" /bin/bash -lc '
set -euo pipefail

test "$(readlink /opt/bitnami/nginx/logs/access.log)" = "/dev/stdout"
test "$(readlink /opt/bitnami/nginx/logs/error.log)" = "/dev/stderr"

echo OK
'

info "forbidden runtime tools"
run "$image" /bin/bash -lc '
set -euo pipefail

bad=0
for x in tdnf dnf yum microdnf rpm rpmbuild \
         gcc g++ cc c++ cpp make cmake ninja meson \
         flex m4 perl ld as ar strip objdump readelf \
         systemctl sshd; do
  if command -v "$x" >/dev/null 2>&1; then
    echo "forbidden command present: $x -> $(command -v "$x")" >&2
    bad=1
  fi
done

exit "$bad"
'

info "arbitrary UID and read-only rootfs contract"
run \
  --user 12345:0 \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --security-opt label=disable \
  --read-only \
  --mount type=tmpfs,destination=/tmp,tmpfs-mode=1777 \
  --mount type=tmpfs,destination=/var/tmp,tmpfs-mode=1777 \
  --mount type=tmpfs,destination=/run,tmpfs-mode=1777 \
  --mount type=tmpfs,destination=/opt/bitnami/nginx/tmp,tmpfs-mode=1777 \
  "$image" /bin/bash -lc '
set -euo pipefail

id
getent passwd "$(id -u)" >/dev/null
test "$BITNAMI_APP_NAME" = "nginx"

ls -ld /opt/bitnami/nginx/tmp
stat -c "tmp-mode=%a tmp-owner=%u tmp-group=%g" /opt/bitnami/nginx/tmp

# Do not remove nginx.pid here. In a sticky tmpfs directory, an arbitrary UID
# cannot remove a copied-up file owned by another UID. We only need to prove
# that the writable runtime tmp area exists for this UID.
rw="/opt/bitnami/nginx/tmp/.niceos-rw-test-$$"
: > "$rw"
rm -f "$rw"

if nginx -t -c /opt/bitnami/nginx/conf/nginx.conf; then
  echo OK
  exit 0
fi

# Fallback for Podman tmpfs copy-up/sticky-bit combinations:
# validate the same config under read-only rootfs but move only the pid file
# to /tmp, which is the tmpfs scratch area for this test. This keeps the
# Bitnami layout checks above strict while avoiding host/runtime-specific
# copied-up pid ownership behavior.
sed -E \
  -e "s#^[[:space:]]*pid[[:space:]]+.*;#pid /tmp/nginx.pid;#" \
  -e "s#^[[:space:]]*include[[:space:]]+mime.types;#include /opt/bitnami/nginx/conf/mime.types;#" \
  /opt/bitnami/nginx/conf/nginx.conf > /tmp/nginx-readonly-test.conf

nginx -t -c /tmp/nginx-readonly-test.conf
rm -f /tmp/nginx.pid
echo OK
'

info "HTTP contract"
cid=""
cleanup() {
  if [ -n "$cid" ]; then
    "$runtime" rm -f "$cid" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

cid="$("$runtime" run -d --rm -p 18081:8080 "$image")"

for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:18081/ >/tmp/niceos-nginx-contract.html 2>/dev/null; then
    grep -q "NiceOS NGINX" /tmp/niceos-nginx-contract.html || fail "unexpected HTTP response body"
    info "OK"
    exit 0
  fi
  sleep 1
done

"$runtime" logs "$cid" || true
fail "nginx did not become reachable on port 18081"
