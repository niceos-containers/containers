#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

niceos_image="${1:?usage: tests/compare-with-bitnami.sh NICEOS_IMAGE [BITNAMI_IMAGE]}"
bitnami_image="${2:-${BITNAMI_IMAGE:-docker.io/bitnami/nginx-exporter:1.5.1}}"
engine="${CONTAINER_ENGINE:-podman}"

echo "==> Compare NiceOS nginx-exporter with Bitnami reference"
echo "NiceOS:  ${niceos_image}"
echo "Bitnami: ${bitnami_image}"

if ! "${engine}" pull "${bitnami_image}" >/dev/null 2>&1; then
  echo "SKIP: unable to pull Bitnami reference image. Current Bitnami Secure Images may require entitlement."
  exit 0
fi

collect() {
  local image="$1"
  "${engine}" run --rm --entrypoint /bin/bash "${image}" -lc '
set -e
printf "uid=%s\n" "$(id -u)"
printf "workdir=%s\n" "$(pwd)"
printf "APP_VERSION=%s\n" "${APP_VERSION:-}"
printf "BITNAMI_APP_NAME=%s\n" "${BITNAMI_APP_NAME:-}"
printf "IMAGE_REVISION=%s\n" "${IMAGE_REVISION:-}"
printf "PATH=%s\n" "${PATH:-}"
command -v nginx-prometheus-exporter || true
command -v exporter || true
test -e /opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter && echo "has_opt_bitnami_binary=yes" || echo "has_opt_bitnami_binary=no"
test -e /usr/bin/exporter && echo "has_exporter_alias=yes" || echo "has_exporter_alias=no"
'
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

collect "${niceos_image}" | sort >"${tmpdir}/niceos.txt"
collect "${bitnami_image}" | sort >"${tmpdir}/bitnami.txt"

echo "==> NiceOS contract"
cat "${tmpdir}/niceos.txt"

echo "==> Bitnami contract"
cat "${tmpdir}/bitnami.txt"

grep -q '^uid=1001$' "${tmpdir}/niceos.txt"
grep -q '^BITNAMI_APP_NAME=nginx-exporter$' "${tmpdir}/niceos.txt"
grep -q '^has_exporter_alias=yes$' "${tmpdir}/niceos.txt"
grep -q '^has_opt_bitnami_binary=yes$' "${tmpdir}/niceos.txt"

echo "OK: comparison completed"
