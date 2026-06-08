#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

app_version="${APP_VERSION:-1.5.1}"
niceos_version="${NICEOS_VERSION:-13}"
image_revision="${IMAGE_REVISION:-1}"
image="${1:-${NICEOS_IMAGE:-docker.io/niceos/nginx-exporter:${app_version}-niceos${niceos_version}-r${image_revision}}}"
engine="${CONTAINER_ENGINE:-podman}"
port="${NICEOS_EXPORTER_TEST_PORT:-19114}"
cid=""

cleanup() {
  if [ -n "${cid}" ]; then
    "${engine}" rm -f "${cid}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

http_get() {
  local url="$1"
  if command -v curl >/dev/null 2>&1; then
    curl -fsS "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$url"
  else
    echo "Neither curl nor wget is available on host" >&2
    return 127
  fi
}

echo "==> NiceOS nginx-exporter local compatibility suite: ${image}"

"$(dirname "$0")/smoke.sh" "${image}"
"$(dirname "$0")/bitnami-contract-smoke.sh" "${image}"

echo "==> read-only rootfs and arbitrary UID runtime"
cid="$("${engine}" run -d --rm \
  --user 12345:0 \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --read-only \
  --tmpfs /tmp:rw,nosuid,nodev \
  --tmpfs /var/tmp:rw,nosuid,nodev \
  -p "127.0.0.1:${port}:9113" \
  "${image}" \
  --web.listen-address=:9113 \
  --nginx.scrape-uri=http://127.0.0.1:18080/status \
  --log.level=debug)"

ok=0
for _ in $(seq 1 40); do
  body="$(http_get "http://127.0.0.1:${port}/metrics" 2>/dev/null || true)"
  if printf '%s\n' "${body}" | grep -Eq 'nginx_exporter_build_info|nginx_up|promhttp_metric_handler_requests_total'; then
    ok=1
    break
  fi
  sleep 0.25
done

if [ "${ok}" != "1" ]; then
  echo "Exporter did not expose metrics under read-only/arbitrary UID mode" >&2
  "${engine}" logs "${cid}" >&2 || true
  exit 1
fi

"${engine}" rm -f "${cid}" >/dev/null 2>&1 || true
cid=""

echo "==> optional pod-level scrape against NiceOS NGINX"
nginx_image="${NICEOS_NGINX_IMAGE:-docker.io/niceos/nginx:1.31.1-niceos13-r1}"
if "${engine}" image exists "${nginx_image}" >/dev/null 2>&1; then
  pod_name="niceos-nginx-exporter-test-$$"
  "${engine}" pod create --name "${pod_name}" -p "127.0.0.1:${port}:9113" >/dev/null
  trap '"${engine}" pod rm -f "'"${pod_name}"'" >/dev/null 2>&1 || true; cleanup' EXIT

  "${engine}" run -d --rm --pod "${pod_name}" --name "${pod_name}-nginx" "${nginx_image}" >/dev/null
  "${engine}" run -d --rm --pod "${pod_name}" --name "${pod_name}-exporter" \
    "${image}" \
    --web.listen-address=:9113 \
    --nginx.scrape-uri="${NICEOS_NGINX_SCRAPE_URI:-http://127.0.0.1:8080/status}" >/dev/null

  ok=0
  for _ in $(seq 1 60); do
    body="$(http_get "http://127.0.0.1:${port}/metrics" 2>/dev/null || true)"
    if printf '%s\n' "${body}" | grep -Eq 'nginx_up|nginx_connections_active|nginx_exporter_build_info'; then
      ok=1
      break
    fi
    sleep 0.5
  done

  "${engine}" pod rm -f "${pod_name}" >/dev/null 2>&1 || true

  if [ "${ok}" != "1" ]; then
    echo "Pod-level scrape test failed" >&2
    exit 1
  fi
else
  echo "SKIP: ${nginx_image} is not available locally. Pull it or set NICEOS_NGINX_IMAGE to enable this check."
fi

echo "OK: local compatibility suite passed"
