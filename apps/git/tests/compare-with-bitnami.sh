#!/usr/bin/env bash
set -euo pipefail

NICEOS_IMAGE="${1:-docker.io/niceosapps/git:2.53.0-niceos13-r1}"
BITNAMI_IMAGE="${2:-docker.io/bitnami/git:latest}"

OUTDIR="${OUTDIR:-/tmp/git-image-compare}"
rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

collect() {
    local image="$1"
    local name="$2"

    echo "Collecting: $name -> $image"

    podman run --rm "$image" /bin/bash -lc '
set -euo pipefail

echo "## env"
env | sort | grep -E "^(APP_VERSION|BITNAMI_APP_NAME|IMAGE_REVISION|NSS_WRAPPER_LIB|OS_ARCH|OS_FLAVOUR|OS_NAME|PATH)=" || true

echo
echo "## command paths"
for x in git bash ssh ssh-keygen ssh-agent ssh-add scp sftp curl ps getent id; do
    printf "%s=" "$x"
    command -v "$x" || true
done

echo
echo "## versions"
git --version || true
ssh -V 2>&1 || true
curl --version | head -1 || true
bash --version | head -1 || true

echo
echo "## required paths"
for p in \
  /opt/bitnami \
  /opt/bitnami/scripts/git/entrypoint.sh \
  /opt/bitnami/git/bin/git \
  /opt/bitnami/common/lib/libnss_wrapper.so \
  /etc/ssh \
  /bitnami/git
do
    if [ -e "$p" ]; then
        ls -ld "$p"
    else
        echo "MISSING $p"
    fi
done

echo
echo "## git config"
git config --system --list || true

echo
echo "## git exec path"
git --exec-path || true

echo
echo "## git help -a first lines"
git help -a | head -80 || true
' > "${OUTDIR}/${name}.txt"
}

collect "$BITNAMI_IMAGE" bitnami
collect "$NICEOS_IMAGE" niceos

echo
echo "== diff =="
diff -u "${OUTDIR}/bitnami.txt" "${OUTDIR}/niceos.txt" || true

echo
echo "Reports:"
echo "${OUTDIR}/bitnami.txt"
echo "${OUTDIR}/niceos.txt"
