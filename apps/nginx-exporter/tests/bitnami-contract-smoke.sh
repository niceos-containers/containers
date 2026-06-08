#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

app_version="${APP_VERSION:-1.5.1}"
niceos_version="${NICEOS_VERSION:-13}"
image_revision="${IMAGE_REVISION:-1}"
image="${1:-${NICEOS_IMAGE:-docker.io/niceos/nginx-exporter:${app_version}-niceos${niceos_version}-r${image_revision}}}"
engine="${CONTAINER_ENGINE:-podman}"

run_bash() {
  "${engine}" run --rm --entrypoint /bin/bash "$image" -lc "$1"
}

echo "==> Bitnami-compatible nginx-exporter contract: ${image}"

echo "==> environment, user and command path contract"
run_bash '
set -euo pipefail

test "$(id -u)" = "1001"

test "${BITNAMI_APP_NAME:-}" = "nginx-exporter"
test "${BITNAMI_ROOT_DIR:-}" = "/opt/bitnami"
test -n "${APP_VERSION:-}"
test -n "${IMAGE_REVISION:-}"
test -n "${NICEOS_CONTAINER_STREAM:-}"

case ":${PATH}:" in
  *:/opt/bitnami/nginx-exporter/bin:*) ;;
  *) echo "PATH does not include /opt/bitnami/nginx-exporter/bin: ${PATH}" >&2; exit 1 ;;
esac

command -v nginx-prometheus-exporter
command -v exporter

test -e /opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter
test -x /opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter
test -e /usr/bin/exporter
test -x /usr/bin/exporter

nginx-prometheus-exporter --version >/dev/null 2>&1 || nginx-prometheus-exporter --help >/dev/null 2>&1
exporter --version >/dev/null 2>&1 || exporter --help >/dev/null 2>&1
'

echo "==> filesystem layout contract"
run_bash '
set -euo pipefail

test -d /opt/bitnami
test -d /opt/bitnami/nginx-exporter
test -d /opt/bitnami/nginx-exporter/bin
test -d /opt/bitnami/scripts
test -f /.niceos-image-release

grep -q "^APP_NAME=nginx-exporter$" /.niceos-image-release
grep -q "^BITNAMI_COMPAT_REFERENCE=bitnami/nginx-exporter/1/debian-12$" /.niceos-image-release
'

echo "==> runtime minimization contract"
run_bash '
set -euo pipefail

for forbidden in tdnf dnf yum microdnf rpm rpmbuild gcc g++ cc go make cmake ninja meson systemctl sshd; do
  if command -v "${forbidden}" >/dev/null 2>&1; then
    echo "Forbidden runtime command is present: ${forbidden}" >&2
    exit 1
  fi
done

if find / -perm /6000 -type f -print 2>/dev/null | grep -q .; then
  echo "Unexpected setuid/setgid files found:" >&2
  find / -perm /6000 -type f -print 2>/dev/null >&2 || true
  exit 1
fi
'

echo "==> arbitrary UID shell contract"
"${engine}" run --rm --user 12345:0 --entrypoint /bin/bash "${image}" -lc '
set -euo pipefail
test "$(id -u)" = "12345"
command -v nginx-prometheus-exporter
command -v exporter
nginx-prometheus-exporter --version >/dev/null 2>&1 || nginx-prometheus-exporter --help >/dev/null 2>&1
'

echo "OK: Bitnami-compatible contract test passed"
