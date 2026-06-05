#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-docker.io/niceosapps/git:2.53.0-niceos13-r1}"

run() {
    echo
    echo "== $* =="
    "$@"
}

run podman run --rm "$IMAGE" git --version

run podman run --rm "$IMAGE" /bin/bash -lc '
set -e
test "$BITNAMI_APP_NAME" = "git"
test "$APP_VERSION" = "2.53.0"
test "$NSS_WRAPPER_LIB" = "/opt/bitnami/common/lib/libnss_wrapper.so"
test -x /opt/bitnami/scripts/git/entrypoint.sh
test -x /opt/bitnami/git/bin/git
test -e /opt/bitnami/common/lib/libnss_wrapper.so
command -v git
command -v ssh
command -v ssh-keygen
command -v curl
git --version
ssh -V
'

run podman run --rm "$IMAGE" /bin/bash -lc '
set -e
for x in rpm tdnf dnf yum systemctl sshd gcc make cmake ninja meson; do
    if command -v "$x" >/dev/null 2>&1; then
        echo "FORBIDDEN: $x"
        exit 1
    fi
done
for d in /var/lib/rpm /etc/yum.repos.d /var/cache/tdnf /var/lib/tdnf /usr/lib/systemd /usr/lib64/systemd; do
    if [ -e "$d" ]; then
        echo "FORBIDDEN PATH: $d"
        exit 1
    fi
done
echo OK
'

run podman run --rm --user 1001:0 "$IMAGE" /bin/bash -lc '
set -e
id
git --version
'

run podman run --rm --user 12345:0 "$IMAGE" /bin/bash -lc '
set -e
id
getent passwd "$(id -u)"
git --version
'

run podman run --rm "$IMAGE" /bin/bash -lc '
set -e
test -s /etc/pki/tls/certs/ca-bundle.crt
curl -I https://github.com >/dev/null
git ls-remote https://github.com/git/git.git HEAD >/dev/null
'

run podman run --rm "$IMAGE" /bin/bash -lc '
set -e
ssh-keygen -q -t ed25519 -N "" -f /tmp/test_ed25519
test -s /tmp/test_ed25519
test -s /tmp/test_ed25519.pub
ssh-keygen -lf /tmp/test_ed25519.pub
'

run podman run --rm "$IMAGE" /bin/bash -lc '
set -e
test -f /etc/ssh/ssh_host_rsa_key
test -f /etc/ssh/ssh_host_ecdsa_key
test -f /etc/ssh/ssh_host_ed25519_key
ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
'

run podman run --rm "$IMAGE" /bin/bash -lc '
set -e
if find / -perm /6000 -type f 2>/dev/null | grep -q .; then
    echo "SUID/SGID files found:"
    find / -perm /6000 -type f 2>/dev/null
    exit 1
fi
echo OK
'

echo
echo "All smoke tests passed."
