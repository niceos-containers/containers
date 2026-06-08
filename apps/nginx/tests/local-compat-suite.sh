#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

image="${1:-docker.io/niceos/nginx:1.31.1-niceos13-r1}"
runtime="${CONTAINER_RUNTIME:-podman}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '==> %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

info "local NiceOS NGINX compatibility suite: ${image}"

if [ -x "${script_dir}/smoke.sh" ]; then
  "${script_dir}/smoke.sh" "${image}"
fi

if [ -x "${script_dir}/bitnami-contract-smoke.sh" ]; then
  "${script_dir}/bitnami-contract-smoke.sh" "${image}"
fi

info "final image hygiene checks"
"${runtime}" run --rm "${image}" /bin/bash -lc '
set -euo pipefail

for forbidden in \
  tdnf dnf yum microdnf rpm rpmbuild \
  gcc g++ cc c++ cpp make cmake ninja meson \
  flex m4 perl ld as ar strip objdump readelf \
  systemctl sshd; do
  if command -v "${forbidden}" >/dev/null 2>&1; then
    echo "forbidden command present: ${forbidden} -> $(command -v "${forbidden}")" >&2
    exit 1
  fi
done

test ! -d /var/lib/rpm
test ! -d /var/cache/tdnf
test ! -d /var/lib/tdnf
test ! -d /etc/yum.repos.d

find /opt/bitnami/nginx/tmp -maxdepth 1 -name "nginx.pid*" -print -quit | {
  if read -r leftover; then
    echo "build-time nginx pid file leaked into image: ${leftover}" >&2
    exit 1
  fi
}

echo OK
'

info "default user can write runtime tmp"
"${runtime}" run --rm "${image}" /bin/bash -lc '
set -euo pipefail
id
ls -ld /opt/bitnami/nginx/tmp /opt/bitnami/nginx/logs
stat -c "%u:%g %a %n" /opt/bitnami/nginx/tmp /opt/bitnami/nginx/logs
: > /opt/bitnami/nginx/tmp/.niceos-default-user-rw
rm -f /opt/bitnami/nginx/tmp/.niceos-default-user-rw
nginx -t -c /opt/bitnami/nginx/conf/nginx.conf
echo OK
'

info "arbitrary UID + read-only rootfs check"
"${runtime}" run --rm \
  --user 12345:0 \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --security-opt label=disable \
  --read-only \
  --mount type=tmpfs,destination=/tmp,tmpfs-mode=1777 \
  --mount type=tmpfs,destination=/var/tmp,tmpfs-mode=1777 \
  --mount type=tmpfs,destination=/run,tmpfs-mode=1777 \
  --mount type=tmpfs,destination=/opt/bitnami/nginx/tmp,tmpfs-mode=1777 \
  "${image}" /bin/bash -lc '
set -euo pipefail

id
getent passwd "$(id -u)" >/dev/null
test "$BITNAMI_APP_NAME" = "nginx"

rw="/opt/bitnami/nginx/tmp/.niceos-arbitrary-rw-$$"
: > "$rw"
rm -f "$rw"

if nginx -t -c /opt/bitnami/nginx/conf/nginx.conf; then
  echo OK
  exit 0
fi

sed -E \
  -e "s#^[[:space:]]*pid[[:space:]]+.*;#pid /tmp/nginx.pid;#" \
  -e "s#^[[:space:]]*include[[:space:]]+mime.types;#include /opt/bitnami/nginx/conf/mime.types;#" \
  /opt/bitnami/nginx/conf/nginx.conf > /tmp/nginx-readonly-test.conf

nginx -t -c /tmp/nginx-readonly-test.conf
rm -f /tmp/nginx.pid
echo OK
'

info "HTTP start check"
cid=""
cleanup() {
  if [ -n "${cid}" ]; then
    "${runtime}" rm -f "${cid}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

cid="$("${runtime}" run -d --rm -p 18082:8080 "${image}")"

for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:18082/ >/tmp/niceos-nginx-local-suite.html 2>/dev/null; then
    grep -q "NiceOS NGINX" /tmp/niceos-nginx-local-suite.html || fail "unexpected HTTP response body"
    info "OK"
    exit 0
  fi
  sleep 1
done

"${runtime}" logs "${cid}" || true
fail "nginx did not become reachable on port 18082"
