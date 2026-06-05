#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-docker.io/niceosapps/git:2.53.0-niceos13-r1}"

run() {
    echo
    echo "== $* =="
    "$@"
}

echo "Testing image: ${IMAGE}"

run podman image inspect "${IMAGE}" >/dev/null

run podman run --rm "${IMAGE}" git --version

run podman run --rm "${IMAGE}" /bin/bash -lc '
set -euo pipefail

echo "== env =="
test "${BITNAMI_APP_NAME}" = "git"
test "${NSS_WRAPPER_LIB}" = "/opt/bitnami/common/lib/libnss_wrapper.so"
echo "$PATH" | grep -q "/opt/bitnami/git/bin"
echo "$PATH" | grep -q "/opt/bitnami/common/bin"

echo "== required paths =="
test -d /opt/bitnami
test -d /opt/bitnami/scripts
test -x /opt/bitnami/scripts/git/entrypoint.sh
test -x /opt/bitnami/git/bin/git
test -e /opt/bitnami/common/lib/libnss_wrapper.so
test -d /etc/ssh
test -d /bitnami/git

echo "== required commands =="
for x in bash git ssh ssh-keygen ssh-agent ssh-add scp sftp curl ps getent id grep sed awk find; do
    command -v "$x" >/dev/null
done

echo "== forbidden commands =="
for x in rpm tdnf dnf yum systemctl sshd gcc make cmake ninja perl; do
    if command -v "$x" >/dev/null 2>&1; then
        echo "FORBIDDEN COMMAND FOUND: $x -> $(command -v "$x")"
        exit 1
    fi
done

echo "== forbidden paths =="
for p in /var/lib/rpm /etc/yum.repos.d /var/cache/tdnf /var/lib/tdnf /usr/lib/systemd /usr/lib64/systemd; do
    if [ -e "$p" ]; then
        echo "FORBIDDEN PATH FOUND: $p"
        exit 1
    fi
done

echo OK
'

run podman run --rm "${IMAGE}" /bin/bash -lc '
set -euo pipefail

echo "== git local behaviour =="
tmp="$(mktemp -d)"
cd "$tmp"
git init repo
cd repo
git config user.email "test@example.local"
git config user.name "NiceOS Test"
echo hello > README.md
git add README.md
git commit -m "initial"
git status --short
git log --oneline -1
git rev-parse --is-inside-work-tree
'

run podman run --rm "${IMAGE}" /bin/bash -lc '
set -euo pipefail

echo "== git https behaviour =="
test -s /etc/pki/tls/certs/ca-bundle.crt
curl -I https://github.com >/dev/null
git ls-remote https://github.com/git/git.git HEAD >/dev/null
'

run podman run --rm "${IMAGE}" /bin/bash -lc '
set -euo pipefail

echo "== ssh client behaviour =="
ssh -V
ssh-keygen -q -t ed25519 -N "" -f /tmp/test_ed25519
test -s /tmp/test_ed25519
test -s /tmp/test_ed25519.pub
ssh-keygen -lf /tmp/test_ed25519.pub
ssh-agent -s >/tmp/agent.env
grep -q SSH_AUTH_SOCK /tmp/agent.env
'

run podman run --rm --user 1001:0 "${IMAGE}" /bin/bash -lc '
set -euo pipefail
echo "== fixed non-root UID 1001 =="
id
git --version
getent passwd "$(id -u)"
'

run podman run --rm --user 12345:0 "${IMAGE}" /bin/bash -lc '
set -euo pipefail
echo "== arbitrary UID with nss_wrapper =="
id
getent passwd "$(id -u)"
git --version
'

run podman run --rm "${IMAGE}" /bin/bash -lc '
set -euo pipefail
echo "== runtime ssh host keys =="
test -f /etc/ssh/ssh_host_rsa_key
test -f /etc/ssh/ssh_host_ecdsa_key
test -f /etc/ssh/ssh_host_ed25519_key
ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
'

echo
echo "== baked ssh host key check =="
cid="$(podman create --entrypoint /bin/bash "${IMAGE}" -lc "true")"
if podman export "$cid" | tar -tf - | grep -q "^etc/ssh/ssh_host_"; then
    echo "BAD: ssh host keys are baked into image layer"
    podman rm "$cid" >/dev/null
    exit 1
fi
podman rm "$cid" >/dev/null
echo "OK: no baked ssh host keys"

run podman run --rm "${IMAGE}" /bin/bash -lc '
set -euo pipefail
echo "== SUID/SGID check =="
if find / -perm /6000 -type f 2>/dev/null | grep -q .; then
    echo "BAD: SUID/SGID files found"
    find / -perm /6000 -type f 2>/dev/null
    exit 1
fi
echo OK
'

echo
echo "All Bitnami image-contract smoke tests passed."
