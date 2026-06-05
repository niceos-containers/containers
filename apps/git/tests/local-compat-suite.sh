#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-docker.io/niceosapps/git:2.53.0-niceos13-r1}"

run() {
    echo
    echo "== $* =="
    "$@"
}

echo "Testing: $IMAGE"

run podman image inspect "$IMAGE" >/dev/null

echo
echo "== inspect entrypoint/cmd/env =="
podman image inspect "$IMAGE" --format '
Entrypoint={{json .Config.Entrypoint}}
Cmd={{json .Config.Cmd}}
Env={{json .Config.Env}}
' | tee /tmp/niceos-git-inspect.txt

grep -q '/opt/bitnami/scripts/git/entrypoint.sh' /tmp/niceos-git-inspect.txt
grep -q '/bin/bash' /tmp/niceos-git-inspect.txt
grep -q 'BITNAMI_APP_NAME=git' /tmp/niceos-git-inspect.txt
grep -q 'NSS_WRAPPER_LIB=/opt/bitnami/common/lib/libnss_wrapper.so' /tmp/niceos-git-inspect.txt

run podman run --rm "$IMAGE" git --version

run podman run --rm "$IMAGE" /bin/bash -c '
set -euo pipefail
echo "PATH=$PATH"
echo "$PATH" | grep -q "/opt/bitnami/git/bin"
echo "$PATH" | grep -q "/opt/bitnami/common/bin"
test "$(command -v git)" = "/opt/bitnami/git/bin/git"
test "$BITNAMI_APP_NAME" = "git"
test "$NSS_WRAPPER_LIB" = "/opt/bitnami/common/lib/libnss_wrapper.so"
test -x /opt/bitnami/scripts/git/entrypoint.sh
test -x /opt/bitnami/git/bin/git
test -e /opt/bitnami/common/lib/libnss_wrapper.so
test -d /etc/ssh
git --version
'

echo
echo "== login shell PATH check =="
podman run --rm "$IMAGE" /bin/bash -lc '
set -e
echo "PATH=$PATH"
command -v git
' | tee /tmp/niceos-git-login-path.txt

if ! grep -q "/opt/bitnami/git/bin/git" /tmp/niceos-git-login-path.txt; then
    echo "WARN: login shell does not prefer /opt/bitnami/git/bin/git"
    echo "Fix /etc/profile.d/bitnami-path.sh if strict Bitnami parity is required."
fi

run podman run --rm "$IMAGE" /bin/bash -c '
set -euo pipefail
for x in bash git ssh ssh-keygen ssh-agent ssh-add scp sftp curl ps getent id grep sed awk find tar gzip xz; do
    command -v "$x" >/dev/null || { echo "missing $x"; exit 1; }
done
echo OK
'

run podman run --rm "$IMAGE" /bin/bash -c '
set -euo pipefail
for x in rpm tdnf dnf yum systemctl sshd gcc make cmake ninja perl; do
    if command -v "$x" >/dev/null 2>&1; then
        echo "FORBIDDEN command: $x -> $(command -v "$x")"
        exit 1
    fi
done
for p in /var/lib/rpm /etc/yum.repos.d /var/cache/tdnf /var/lib/tdnf /usr/lib/systemd /usr/lib64/systemd /usr/lib/perl5; do
    if [ -e "$p" ]; then
        echo "FORBIDDEN path: $p"
        exit 1
    fi
done
echo OK
'

run podman run --rm "$IMAGE" /bin/bash -c '
set -euo pipefail
tmp="$(mktemp -d)"
cd "$tmp"
git init repo
cd repo
git config user.email test@example.local
git config user.name "NiceOS Test"
echo hello > README.md
git add README.md
git commit -m "initial"
git status --short
git log --oneline -1
git rev-parse --is-inside-work-tree
'

run podman run --rm "$IMAGE" /bin/bash -c '
set -euo pipefail
test -s /etc/pki/tls/certs/ca-bundle.crt
curl -I https://github.com >/dev/null
git ls-remote https://github.com/git/git.git HEAD >/dev/null
echo OK
'

run podman run --rm "$IMAGE" /bin/bash -c '
set -euo pipefail
ssh -V
ssh-keygen -q -t ed25519 -N "" -f /tmp/test_ed25519
test -s /tmp/test_ed25519
test -s /tmp/test_ed25519.pub
ssh-keygen -lf /tmp/test_ed25519.pub
ssh-agent -s >/tmp/agent.env
grep -q SSH_AUTH_SOCK /tmp/agent.env
echo OK
'

run podman run --rm --user 1001:0 "$IMAGE" /bin/bash -c '
set -euo pipefail
id
getent passwd "$(id -u)"
git --version
'

run podman run --rm --user 12345:0 "$IMAGE" /bin/bash -c '
set -euo pipefail
id
getent passwd "$(id -u)"
git --version
'

run podman run --rm --read-only --tmpfs /tmp:rw,exec,nosuid,nodev --tmpfs /var/tmp:rw,exec,nosuid,nodev --tmpfs /run:rw,nosuid,nodev "$IMAGE" /bin/bash -c '
set -euo pipefail
git --version
ssh-keygen -q -t ed25519 -N "" -f /tmp/ro_test_key
git ls-remote https://github.com/git/git.git HEAD >/dev/null
echo OK
'

run podman run --rm "$IMAGE" /bin/bash -c '
set -euo pipefail
test -f /etc/ssh/ssh_host_rsa_key
test -f /etc/ssh/ssh_host_ecdsa_key
test -f /etc/ssh/ssh_host_ed25519_key
ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
'

echo
echo "== baked host key check =="
cid="$(podman create --entrypoint /bin/bash "$IMAGE" -c true)"
if podman export "$cid" | tar -tf - | grep -q "^etc/ssh/ssh_host_"; then
    echo "BAD: ssh host keys are baked into the image"
    podman rm "$cid" >/dev/null
    exit 1
fi
podman rm "$cid" >/dev/null
echo "OK: no baked host keys"

run podman run --rm "$IMAGE" /bin/bash -c '
set -euo pipefail
if find / -perm /6000 -type f 2>/dev/null | grep -q .; then
    echo "BAD: SUID/SGID files found"
    find / -perm /6000 -type f 2>/dev/null
    exit 1
fi
echo OK
'

echo
echo "ALL LOCAL COMPAT TESTS PASSED"
