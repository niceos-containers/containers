#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

app_version="${APP_VERSION:-1.5.1}"
niceos_version="${NICEOS_VERSION:-13}"
image_revision="${IMAGE_REVISION:-1}"
image="${1:-${NICEOS_IMAGE:-docker.io/niceos/nginx-exporter:${app_version}-niceos${niceos_version}-r${image_revision}}}"
engine="${CONTAINER_ENGINE:-podman}"
port="${NICEOS_EXPORTER_TEST_PORT:-19113}"
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

echo "==> NiceOS nginx-exporter smoke: ${image}"

echo "==> version command"
"${engine}" run --rm "${image}" --version >/dev/null 2>&1 || \
"${engine}" run --rm "${image}" --help >/dev/null 2>&1

echo "==> exporter alias command"
"${engine}" run --rm --entrypoint exporter "${image}" --version >/dev/null 2>&1 || \
"${engine}" run --rm --entrypoint exporter "${image}" --help >/dev/null 2>&1

echo "==> start exporter and scrape /metrics"
cid="$("${engine}" run -d --rm \
  -p "127.0.0.1:${port}:9113" \
  "${image}" \
  --web.listen-address=:9113 \
  --nginx.scrape-uri=http://127.0.0.1:18080/stub_status \
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
  echo "Exporter did not expose expected metrics" >&2
  "${engine}" logs "${cid}" >&2 || true
  exit 1
fi

echo "OK: smoke test passed"
