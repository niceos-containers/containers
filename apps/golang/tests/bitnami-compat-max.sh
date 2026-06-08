#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# NiceOS Golang strict Bitnami-compatibility test suite.
#
# This version is for the strict bitnami/golang-style Docker contract:
#
#   - no ENTRYPOINT
#   - no default USER, therefore default runtime user is root
#   - CMD ["bash"]
#   - WORKDIR /go
#   - GOPATH=/go
#   - GOCACHE=/go/.cache
#   - PATH contains /go/bin and /opt/bitnami/go/bin
#   - /go is writable and suitable as the default builder workspace
#
# NiceOS compatibility-plus checks are still included:
#
#   - GOROOT=/opt/bitnami/go
#   - cgo works
#   - Linux UAPI headers exist
#   - libgcc_s linker name exists for cgo
#   - arbitrary UID works when explicitly requested
#   - read-only rootfs works with tmpfs mounts
#   - package managers are absent from the final image
#
# Usage:
#
#   IMAGE=docker.io/niceos/golang:1.26.4-niceos13-r1 \
#   ./tests/bitnami-compat-max.sh
#
# With network tests:
#
#   IMAGE=docker.io/niceos/golang:1.26.4-niceos13-r1 \
#   RUN_NETWORK_TESTS=1 \
#   ./tests/bitnami-compat-max.sh
#
# With Bitnami reference comparison:
#
#   IMAGE=docker.io/niceos/golang:1.26.4-niceos13-r1 \
#   REF_IMAGE=bitnami/golang:1.26.4 \
#   RUN_NETWORK_TESTS=1 \
#   ./tests/bitnami-compat-max.sh

set -Eeuo pipefail

IMAGE="${IMAGE:-docker.io/niceos/golang:1.26.4-niceos13-r1}"
APP_VERSION_EXPECTED="${APP_VERSION_EXPECTED:-1.26.4}"
NICEOS_STREAM_EXPECTED="${NICEOS_STREAM_EXPECTED:-13}"

REF_IMAGE="${REF_IMAGE:-}"

RUN_NETWORK_TESTS="${RUN_NETWORK_TESTS:-0}"
RUN_READONLY_TESTS="${RUN_READONLY_TESTS:-1}"
RUN_SECURITY_TESTS="${RUN_SECURITY_TESTS:-1}"
RUN_SLOW_TESTS="${RUN_SLOW_TESTS:-0}"

# Strict Bitnami Docker config checks:
#   1 = require no ENTRYPOINT and no configured USER
#   0 = allow NiceOS custom ENTRYPOINT/USER
STRICT_BITNAMI_CONFIG="${STRICT_BITNAMI_CONFIG:-1}"

# For current NiceOS image we prefer external GOROOT to be /opt/bitnami/go.
# Set to 0 if you temporarily want to allow /opt/go-<version>.
STRICT_GOROOT="${STRICT_GOROOT:-1}"

TMPDIR_HOST="$(mktemp -d)"
RESULTS_DIR="${RESULTS_DIR:-${PWD}/build/test-results/golang-bitnami-compat}"
mkdir -p "${RESULTS_DIR}"

FAILED=0
PASSED=0
SKIPPED=0

cleanup() {
    rm -rf "${TMPDIR_HOST}"
}
trap cleanup EXIT

log() {
    printf '\n\033[1;36m==> %s\033[0m\n' "$*"
}

pass() {
    PASSED=$((PASSED + 1))
    printf '\033[1;32mPASS\033[0m %s\n' "$*"
}

fail() {
    FAILED=$((FAILED + 1))
    printf '\033[1;31mFAIL\033[0m %s\n' "$*" >&2
}

skip() {
    SKIPPED=$((SKIPPED + 1))
    printf '\033[1;33mSKIP\033[0m %s\n' "$*"
}

run_test() {
    local name="$1"
    shift

    log "${name}"

    set +e
    "$@" >"${RESULTS_DIR}/${name}.log" 2>&1
    local rc=$?
    set -e

    if [ "${rc}" -eq 0 ]; then
        pass "${name}"
    else
        fail "${name}"
        echo "----- ${RESULTS_DIR}/${name}.log -----" >&2
        tail -n 160 "${RESULTS_DIR}/${name}.log" >&2 || true
        echo "--------------------------------------" >&2
    fi
}

run_container() {
    podman run --rm "${IMAGE}" "$@"
}

run_container_root() {
    podman run --rm --user 0:0 "${IMAGE}" "$@"
}

run_container_user() {
    local user="$1"
    shift
    podman run --rm --user "${user}" "${IMAGE}" "$@"
}

run_container_readonly() {
    local user="${1:-1001:0}"
    shift || true

    podman run --rm \
        --user "${user}" \
        --cap-drop ALL \
        --security-opt no-new-privileges \
        --read-only \
        --tmpfs /tmp:rw,exec,nosuid,nodev \
        --tmpfs /var/tmp:rw,exec,nosuid,nodev \
        --tmpfs /run:rw,nosuid,nodev \
        --tmpfs /go:rw,exec,nosuid,nodev \
        --tmpfs /bitnami:rw,exec,nosuid,nodev \
        "${IMAGE}" "$@"
}

image_inspect() {
    podman image inspect "${IMAGE}" "$@"
}

test_image_exists() {
    podman image inspect "${IMAGE}" >/dev/null
}

test_basic_go_version() {
    run_container go version | grep -E "go${APP_VERSION_EXPECTED} .*linux/"
}

test_bitnami_strict_docker_config() {
    image_inspect > "${RESULTS_DIR}/inspect.json"

    local workdir cmd user entrypoint
    workdir="$(image_inspect --format '{{.Config.WorkingDir}}')"
    cmd="$(image_inspect --format '{{json .Config.Cmd}}')"
    user="$(image_inspect --format '{{.Config.User}}')"
    entrypoint="$(image_inspect --format '{{json .Config.Entrypoint}}')"

    echo "WorkingDir=${workdir}"
    echo "Cmd=${cmd}"
    echo "User=${user}"
    echo "Entrypoint=${entrypoint}"

    test "${workdir}" = "/go"
    echo "${cmd}" | grep -q '"bash"'

    if [ "${STRICT_BITNAMI_CONFIG}" = "1" ]; then
        # bitnami/golang has no configured Docker ENTRYPOINT.
        test "${entrypoint}" = "null" || test "${entrypoint}" = "[]"

        # bitnami/golang has no configured Docker USER, so default user is root.
        test -z "${user}" || test "${user}" = "0"
    fi
}

test_default_cmd_bash() {
    # With CMD ["bash"] and no ENTRYPOINT, running the image without arguments
    # should start bash. We make it execute a command through stdin.
    printf 'echo default-bash-ok\n' | podman run --rm -i "${IMAGE}" | grep -q 'default-bash-ok'
}

test_command_passthrough() {
    # Strict bitnami/golang behavior: user-supplied command runs directly,
    # not through a custom entrypoint.
    podman run --rm "${IMAGE}" echo command-passthrough-ok | grep -q 'command-passthrough-ok'
}

test_bash_lc() {
    podman run --rm "${IMAGE}" bash -lc 'echo bash-lc-ok' | grep -q 'bash-lc-ok'
}

test_no_leading_dash_magic() {
    # With no ENTRYPOINT, this is expected to fail because "-lc" is not an executable.
    # This confirms we are not silently wrapping commands with a custom entrypoint.
    if podman run --rm "${IMAGE}" -lc 'echo should-not-run' >/tmp/niceos-leading-dash-test.log 2>&1; then
        echo "Unexpected success for leading-dash command without explicit bash" >&2
        cat /tmp/niceos-leading-dash-test.log >&2 || true
        return 1
    fi
    return 0
}

test_shell_and_core_tools() {
    run_container bash -lc '
set -eux
command -v bash
command -v sh
command -v env
command -v id
command -v pwd
command -v ls
command -v mkdir
command -v chmod
command -v cat
command -v grep
command -v sed
command -v awk
command -v tar
command -v gzip
command -v xz
command -v zstd
command -v git
command -v curl
command -v unzip
command -v procps >/dev/null 2>&1 || command -v ps
'
}

test_bitnami_env_contract() {
    run_container bash -lc "
set -eux

test \"\${APP_VERSION}\" = \"${APP_VERSION_EXPECTED}\"
test \"\${BITNAMI_APP_NAME}\" = \"golang\"
test \"\${GOPATH}\" = \"/go\"
test \"\${GOCACHE}\" = \"/go/.cache\"
test \"\${GOMODCACHE}\" = \"/go/pkg/mod\"
test \"\${OS_NAME}\" = \"linux\"
test \"\${NICEOS_CONTAINER_STREAM}\" = \"${NICEOS_STREAM_EXPECTED}\"

# NiceOS sets HOME=/go for deterministic builder behavior. Bitnami does not
# explicitly set HOME in the Dockerfile, so this is compatibility-plus.
if [ -n \"\${HOME:-}\" ]; then
    echo \"HOME=\${HOME}\"
fi

case \":\${PATH}:\" in
  *:/go/bin:*);;
  *) echo \"PATH does not contain /go/bin: \${PATH}\" >&2; exit 1;;
esac

case \":\${PATH}:\" in
  *:/opt/bitnami/go/bin:*);;
  *) echo \"PATH does not contain /opt/bitnami/go/bin: \${PATH}\" >&2; exit 1;;
esac

echo \"APP_VERSION=\${APP_VERSION}\"
echo \"BITNAMI_IMAGE_VERSION=\${BITNAMI_IMAGE_VERSION:-}\"
echo \"PATH=\${PATH}\"
"
}

test_go_env_contract() {
    run_container bash -lc "
set -eux

test -x /opt/bitnami/go/bin/go
test -x /opt/bitnami/go/bin/gofmt

go env GOROOT
test \"\$(go env GOPATH)\" = \"/go\"
test \"\$(go env GOCACHE)\" = \"/go/.cache\"
test \"\$(go env GOMODCACHE)\" = \"/go/pkg/mod\"

if [ \"${STRICT_GOROOT}\" = \"1\" ]; then
    test \"\$(go env GOROOT)\" = \"/opt/bitnami/go\"
fi
"
}

test_filesystem_layout() {
    run_container bash -lc '
set -eux

test -d /opt
test -d /opt/bitnami
test -e /opt/bitnami/go
test -d /opt/bitnami/go/bin
test -d /opt/bitnami/go/src
test -d /opt/bitnami/go/pkg

# Scripts are optional for strict bitnami/golang because upstream bitnami/golang
# has no app-specific entrypoint. NiceOS may keep scripts for repository
# consistency, but they must not be configured as Docker ENTRYPOINT.
if [ -d /opt/bitnami/scripts/golang ]; then
    ls -la /opt/bitnami/scripts/golang
fi

test -d /go
test -d /go/src
test -d /go/bin
test -d /go/pkg
test -d /go/.cache

test -d /bitnami
test -d /bitnami/golang

ls -la /opt/bitnami
ls -la /opt/bitnami/go
ls -la /go
ls -la /bitnami
'
}

test_go_tree_completeness() {
    run_container bash -lc '
set -eux

# Important: Bitnami once had a regression where go/doc was missing.
test -d /opt/bitnami/go/src/go/doc
test -f /opt/bitnami/go/src/go/doc/doc.go

test -d /opt/bitnami/go/lib/time
test -f /opt/bitnami/go/lib/time/zoneinfo.zip

test -d /opt/bitnami/go/pkg/tool
test -x /opt/bitnami/go/pkg/tool/linux_amd64/compile
test -x /opt/bitnami/go/pkg/tool/linux_amd64/link

test -f /opt/bitnami/go/VERSION
grep -q "go" /opt/bitnami/go/VERSION
'
}

test_permissions_go_workspace() {
    run_container bash -lc '
set -eux

stat -c "%a %U %G %n" /go /go/src /go/bin /go/pkg /go/.cache /tmp /var/tmp

test -w /go
test -w /go/src
test -w /go/bin
test -w /go/pkg
test -w /go/.cache
test -w /tmp
test -w /var/tmp

touch /go/.cache/write-test
touch /go/src/write-test
touch /go/pkg/write-test
touch /go/bin/write-test

# bitnami/golang-style workspace should be world-writable.
perm="$(stat -c "%a" /go)"
case "${perm}" in
    777|1777) ;;
    *) echo "Unexpected /go permissions: ${perm}; expected 777 or 1777" >&2; exit 1 ;;
esac
'
}

test_default_user_root() {
    run_container bash -lc '
set -eux
id
test "$(id -u)" = "0"
getent passwd "$(id -u)"
'
}

test_root_user_explicit() {
    run_container_user 0:0 bash -lc '
set -eux
id
test "$(id -u)" = "0"
go version
go env GOPATH
'
}

test_explicit_uid_1001_root_group() {
    run_container_user 1001:0 bash -lc '
set -eux
id
test "$(id -u)" = "1001"
test "$(id -g)" = "0"
test -w /go
go version
'
}

test_arbitrary_uid_root_group() {
    run_container_user 12345:0 bash -lc '
set -eux
id
test "$(id -u)" = "12345"
test "$(id -g)" = "0"
test -w /go
go version

cat > /tmp/hello.go <<EOF
package main
import "fmt"
func main(){ fmt.Println("arbitrary-uid-root-group-ok") }
EOF

go run /tmp/hello.go
'
}

test_arbitrary_uid_arbitrary_gid() {
    run_container_user 12345:12345 bash -lc '
set -eux
id
test "$(id -u)" = "12345"
go version

# /go is expected to be 0777 in Bitnami-style Golang, so arbitrary gid should work.
test -w /go

cat > /tmp/hello.go <<EOF
package main
import "fmt"
func main(){ fmt.Println("arbitrary-uid-gid-ok") }
EOF

go run /tmp/hello.go
'
}

test_go_run_simple() {
    run_container bash -lc '
set -eux

cat > /tmp/hello.go <<EOF
package main
import "fmt"
func main(){ fmt.Println("niceos-golang-ok") }
EOF

go run /tmp/hello.go
'
}

test_go_module_workflow() {
    run_container bash -lc '
set -eux

mkdir -p /go/src/niceos-test
cd /go/src/niceos-test

go mod init example.com/niceos-test

cat > main.go <<EOF
package main
import "fmt"
func main(){ fmt.Println("niceos-go-module-ok") }
EOF

go run .
go build -o /go/bin/niceos-test .
/go/bin/niceos-test
'
}

test_go_workspaces() {
    run_container bash -lc '
set -eux

mkdir -p /go/src/ws/a /go/src/ws/b

cd /go/src/ws/a
go mod init example.com/a
cat > a.go <<EOF
package a
func Value() string { return "a-ok" }
EOF

cd /go/src/ws/b
go mod init example.com/b
cat > main.go <<EOF
package main
import (
    "fmt"
    "example.com/a"
)
func main(){ fmt.Println(a.Value()) }
EOF

cd /go/src/ws
go work init ./a ./b
cat go.work

cd /go/src/ws/b
go run .
'
}

test_go_doc_package() {
    run_container bash -lc '
set -eux

cat > /tmp/godoc.go <<EOF
package main

import (
    "fmt"
    "go/doc"
)

func main() {
    _ = doc.Package{}
    fmt.Println("go-doc-ok")
}
EOF

go run /tmp/godoc.go
'
}

test_cgo_malloc() {
    run_container bash -lc '
set -eux

cat > /tmp/cgo.go <<EOF
package main

/*
#include <stdlib.h>
*/
import "C"
import "fmt"

func main() {
    p := C.malloc(8)
    if p == nil {
        panic("malloc failed")
    }
    C.free(p)
    fmt.Println("niceos-cgo-ok")
}
EOF

CGO_ENABLED=1 go run /tmp/cgo.go
'
}

test_cgo_pthread_link() {
    run_container bash -lc '
set -eux

cat > /tmp/pthread.go <<EOF
package main

/*
#include <pthread.h>
#include <stdlib.h>

static void* worker(void* arg) {
    return arg;
}

static int run_thread() {
    pthread_t t;
    void* ret;
    int rc = pthread_create(&t, NULL, worker, NULL);
    if (rc != 0) return rc;
    rc = pthread_join(t, &ret);
    return rc;
}
*/
import "C"
import "fmt"

func main() {
    if C.run_thread() != 0 {
        panic("pthread failed")
    }
    fmt.Println("cgo-pthread-ok")
}
EOF

CGO_ENABLED=1 go run /tmp/pthread.go
'
}

test_static_pure_go_build() {
    run_container bash -lc '
set -eux

mkdir -p /go/src/static-pure
cd /go/src/static-pure
go mod init example.com/static-pure

cat > main.go <<EOF
package main
import "fmt"
func main(){ fmt.Println("static-pure-ok") }
EOF

CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o /go/bin/static-pure .
/go/bin/static-pure
file /go/bin/static-pure || true
'
}

test_dynamic_cgo_build() {
    run_container bash -lc '
set -eux

mkdir -p /go/src/dynamic-cgo
cd /go/src/dynamic-cgo
go mod init example.com/dynamic-cgo

cat > main.go <<EOF
package main

/*
#include <stdlib.h>
*/
import "C"
import "fmt"

func main() {
    p := C.malloc(16)
    C.free(p)
    fmt.Println("dynamic-cgo-ok")
}
EOF

CGO_ENABLED=1 go build -o /go/bin/dynamic-cgo .
/go/bin/dynamic-cgo
ldd /go/bin/dynamic-cgo || true
'
}

test_linux_headers_and_libgcc_devel() {
    run_container bash -lc '
set -eux

test -f /usr/include/linux/errno.h
test -f /usr/include/linux/types.h

find /usr -name "libgcc_s*" -print -exec ls -l {} \;

# Required for gcc -lgcc_s used by cgo linking.
test -e /usr/lib/libgcc_s.so -o -e /usr/lib64/libgcc_s.so
'
}

test_git_curl_ca() {
    run_container bash -lc '
set -eux

git --version
curl --version
test -d /etc/ssl || true
test -d /etc/pki || true
'
}

test_unzip_tar_make_pkgconf() {
    run_container bash -lc '
set -eux

unzip -v | head -n 2
tar --version | head -n 1
make --version | head -n 1
pkg-config --version || pkgconf --version
'
}

test_no_package_managers() {
    run_container bash -lc '
set -eux

! command -v tdnf
! command -v dnf
! command -v yum
! command -v rpm
! command -v rpm2cpio

echo "package-manager-absence-ok"
'
}

test_no_setuid_setgid() {
    run_container_root bash -lc '
set -eux
bad="$(find / -xdev -perm /6000 -type f -print 2>/dev/null || true)"
if [ -n "$bad" ]; then
    echo "Unexpected setuid/setgid files:"
    echo "$bad"
    exit 1
fi
'
}

test_image_release_file() {
    run_container bash -lc '
set -eux
test -f /.niceos-image-release
cat /.niceos-image-release
grep -q "^NAME=golang" /.niceos-image-release
grep -q "^BITNAMI_LAYOUT_COMPATIBLE=yes" /.niceos-image-release
'
}

test_labels() {
    podman image inspect "${IMAGE}" --format '{{json .Labels}}' | tee "${RESULTS_DIR}/labels.json"

    podman image inspect "${IMAGE}" --format '{{index .Labels "org.opencontainers.image.title"}}' | grep -q '^golang$'
    podman image inspect "${IMAGE}" --format '{{index .Labels "ru.niceos.container.bitnami-compatible"}}' | grep -q '^true$'
    podman image inspect "${IMAGE}" --format '{{index .Labels "ru.niceos.container.layout.opt-bitnami"}}' | grep -q '^true$'
}

test_readonly_rootfs_basic() {
    run_container_readonly 1001:0 bash -lc '
set -eux
id
go version
go env GOPATH GOCACHE GOMODCACHE GOROOT
test -w /tmp
test -w /var/tmp
test -w /run
test -w /go
'
}

test_readonly_rootfs_go_module() {
    run_container_readonly 1001:0 bash -lc '
set -eux

mkdir -p /go/src/readonly-test
cd /go/src/readonly-test

go mod init example.com/readonly-test

cat > main.go <<EOF
package main
import "fmt"
func main(){ fmt.Println("readonly-rootfs-ok") }
EOF

go run .
'
}

test_readonly_rootfs_cgo() {
    run_container_readonly 1001:0 bash -lc '
set -eux

cat > /tmp/cgo.go <<EOF
package main
/*
#include <stdlib.h>
*/
import "C"
import "fmt"
func main() {
    p := C.malloc(8)
    C.free(p)
    fmt.Println("readonly-cgo-ok")
}
EOF

CGO_ENABLED=1 go run /tmp/cgo.go
'
}

test_volume_mount_project() {
    local project="${TMPDIR_HOST}/project"
    mkdir -p "${project}"
    chmod 0777 "${project}"

    cat > "${project}/go.mod" <<EOF
module example.com/project

go 1.26.4
EOF

    cat > "${project}/main.go" <<EOF
package main
import "fmt"
func main(){ fmt.Println("mounted-project-ok") }
EOF

    podman run --rm \
        -v "${project}:/go/src/project:Z" \
        "${IMAGE}" \
        bash -lc 'cd /go/src/project && go run .' | grep -q 'mounted-project-ok'
}

test_volume_mount_bitnami() {
    local data="${TMPDIR_HOST}/bitnami"
    mkdir -p "${data}"
    chmod 0777 "${data}"

    podman run --rm \
        -v "${data}:/bitnami:Z" \
        "${IMAGE}" \
        bash -lc '
set -eux
test -d /bitnami
touch /bitnami/write-test
echo bitnami-volume-ok > /bitnami/write-test
cat /bitnami/write-test
' | grep -q 'bitnami-volume-ok'
}

test_network_git_lsremote() {
    [ "${RUN_NETWORK_TESTS}" = "1" ] || { skip "network-git-lsremote"; return 0; }

    run_container bash -lc '
set -eux
git ls-remote https://github.com/bitnami/go-version.git HEAD
'
}

test_network_go_module_download() {
    [ "${RUN_NETWORK_TESTS}" = "1" ] || { skip "network-go-module-download"; return 0; }

    run_container bash -lc '
set -eux

mkdir -p /go/src/network-test
cd /go/src/network-test

go mod init example.com/network-test
go get github.com/google/uuid@latest

cat > main.go <<EOF
package main

import (
    "fmt"
    "github.com/google/uuid"
)

func main() {
    fmt.Println(uuid.NewString() != "")
}
EOF

go run . | grep true
'
}

test_network_go_install_to_gopath_bin() {
    [ "${RUN_NETWORK_TESTS}" = "1" ] || { skip "network-go-install-to-gopath-bin"; return 0; }

    run_container bash -lc '
set -eux

go install github.com/bitnami/go-version/cmd/go-version@latest || go install github.com/rakyll/hey@latest

ls -la /go/bin
test "$(find /go/bin -maxdepth 1 -type f | wc -l)" -ge 1
'
}

test_reference_compare_env_if_available() {
    [ -n "${REF_IMAGE}" ] || { skip "reference-compare-env"; return 0; }

    log "Pulling reference image ${REF_IMAGE}"
    podman pull "${REF_IMAGE}" >/dev/null

    podman run --rm "${REF_IMAGE}" bash -lc 'env | sort' > "${RESULTS_DIR}/ref.env"
    podman run --rm "${IMAGE}" bash -lc 'env | sort' > "${RESULTS_DIR}/niceos.env"

    # Do not require exact equality. Compare contract keys.
    : > "${RESULTS_DIR}/env.compare"
    for key in APP_VERSION BITNAMI_APP_NAME GOPATH GOCACHE PATH HOME OS_NAME OS_ARCH; do
        echo "### ${key}" >> "${RESULTS_DIR}/env.compare"
        grep "^${key}=" "${RESULTS_DIR}/ref.env" >> "${RESULTS_DIR}/env.compare" || true
        grep "^${key}=" "${RESULTS_DIR}/niceos.env" >> "${RESULTS_DIR}/env.compare" || true
    done

    cat "${RESULTS_DIR}/env.compare"
}

test_reference_compare_paths_if_available() {
    [ -n "${REF_IMAGE}" ] || { skip "reference-compare-paths"; return 0; }

    podman run --rm "${REF_IMAGE}" bash -lc '
set -e
for p in /go /go/src /go/bin /go/.cache /opt/bitnami/go /opt/bitnami/go/bin/go /bitnami; do
    if [ -e "$p" ]; then
        stat -c "%F %a %U %G %n" "$p" || true
    else
        echo "MISSING $p"
    fi
done
' > "${RESULTS_DIR}/ref.paths"

    podman run --rm "${IMAGE}" bash -lc '
set -e
for p in /go /go/src /go/bin /go/.cache /opt/bitnami/go /opt/bitnami/go/bin/go /bitnami; do
    if [ -e "$p" ]; then
        stat -c "%F %a %U %G %n" "$p" || true
    else
        echo "MISSING $p"
    fi
done
' > "${RESULTS_DIR}/niceos.paths"

    echo "Reference paths:"
    cat "${RESULTS_DIR}/ref.paths"
    echo
    echo "NiceOS paths:"
    cat "${RESULTS_DIR}/niceos.paths"
}

test_reference_compare_config_if_available() {
    [ -n "${REF_IMAGE}" ] || { skip "reference-compare-config"; return 0; }

    podman image inspect "${REF_IMAGE}" > "${RESULTS_DIR}/ref.inspect.json"
    podman image inspect "${IMAGE}" > "${RESULTS_DIR}/niceos.inspect.json"

    {
        echo "Reference:"
        podman image inspect "${REF_IMAGE}" --format 'User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}} Cmd={{json .Config.Cmd}} Workdir={{.Config.WorkingDir}}'
        echo "NiceOS:"
        podman image inspect "${IMAGE}" --format 'User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}} Cmd={{json .Config.Cmd}} Workdir={{.Config.WorkingDir}}'
    } | tee "${RESULTS_DIR}/config.compare"
}

test_reference_compare_go_env_if_available() {
    [ -n "${REF_IMAGE}" ] || { skip "reference-compare-go-env"; return 0; }

    podman run --rm "${REF_IMAGE}" bash -lc 'go env' > "${RESULTS_DIR}/ref.goenv"
    podman run --rm "${IMAGE}" bash -lc 'go env' > "${RESULTS_DIR}/niceos.goenv"

    : > "${RESULTS_DIR}/goenv.compare"
    for key in GOROOT GOPATH GOCACHE GOMODCACHE GOOS GOARCH CGO_ENABLED CC CXX; do
        echo "### ${key}" >> "${RESULTS_DIR}/goenv.compare"
        grep "^${key}=" "${RESULTS_DIR}/ref.goenv" >> "${RESULTS_DIR}/goenv.compare" || true
        grep "^${key}=" "${RESULTS_DIR}/niceos.goenv" >> "${RESULTS_DIR}/goenv.compare" || true
    done

    cat "${RESULTS_DIR}/goenv.compare"
}

test_slow_stdlib_smoke() {
    [ "${RUN_SLOW_TESTS}" = "1" ] || { skip "slow-stdlib-smoke"; return 0; }

    run_container bash -lc '
set -eux

cat > /tmp/stdlib.go <<EOF
package main

import (
    "archive/tar"
    "bytes"
    "compress/gzip"
    "crypto/sha256"
    "crypto/tls"
    "database/sql"
    "encoding/json"
    "fmt"
    "go/ast"
    "go/doc"
    "html/template"
    "net/http"
    "os"
    "regexp"
    "runtime"
    "time"
)

func main() {
    _ = tar.Header{}
    _ = gzip.NewWriter
    _ = sha256.Sum256([]byte("niceos"))
    _ = tls.VersionTLS13
    _ = sql.ErrNoRows
    _ = json.Valid([]byte("{}"))
    _ = ast.File{}
    _ = doc.Package{}
    _ = template.HTMLEscapeString
    _ = http.MethodGet
    _ = os.Getenv("PATH")
    _ = regexp.MustCompile("niceos")
    _ = runtime.GOOS
    _ = time.Now()
    fmt.Println(bytes.NewBufferString("stdlib-ok").String())
}
EOF

go run /tmp/stdlib.go
'
}

main() {
    log "Testing image: ${IMAGE}"
    mkdir -p "${RESULTS_DIR}"

    run_test image-exists test_image_exists
    run_test basic-go-version test_basic_go_version
    run_test bitnami-strict-docker-config test_bitnami_strict_docker_config
    run_test default-cmd-bash test_default_cmd_bash
    run_test command-passthrough test_command_passthrough
    run_test bash-lc test_bash_lc
    run_test no-leading-dash-magic test_no_leading_dash_magic
    run_test shell-and-core-tools test_shell_and_core_tools
    run_test bitnami-env-contract test_bitnami_env_contract
    run_test go-env-contract test_go_env_contract
    run_test filesystem-layout test_filesystem_layout
    run_test go-tree-completeness test_go_tree_completeness
    run_test permissions-go-workspace test_permissions_go_workspace
    run_test default-user-root test_default_user_root
    run_test root-user-explicit test_root_user_explicit
    run_test explicit-uid-1001-root-group test_explicit_uid_1001_root_group
    run_test arbitrary-uid-root-group test_arbitrary_uid_root_group
    run_test arbitrary-uid-arbitrary-gid test_arbitrary_uid_arbitrary_gid
    run_test go-run-simple test_go_run_simple
    run_test go-module-workflow test_go_module_workflow
    run_test go-workspaces test_go_workspaces
    run_test go-doc-package test_go_doc_package
    run_test cgo-malloc test_cgo_malloc
    run_test cgo-pthread-link test_cgo_pthread_link
    run_test static-pure-go-build test_static_pure_go_build
    run_test dynamic-cgo-build test_dynamic_cgo_build
    run_test linux-headers-and-libgcc-devel test_linux_headers_and_libgcc_devel
    run_test git-curl-ca test_git_curl_ca
    run_test unzip-tar-make-pkgconf test_unzip_tar_make_pkgconf
    run_test no-package-managers test_no_package_managers

    if [ "${RUN_SECURITY_TESTS}" = "1" ]; then
        run_test no-setuid-setgid test_no_setuid_setgid
        run_test labels test_labels
        run_test image-release-file test_image_release_file
    else
        skip "security tests disabled"
    fi

    run_test volume-mount-project test_volume_mount_project
    run_test volume-mount-bitnami test_volume_mount_bitnami

    if [ "${RUN_READONLY_TESTS}" = "1" ]; then
        run_test readonly-rootfs-basic test_readonly_rootfs_basic
        run_test readonly-rootfs-go-module test_readonly_rootfs_go_module
        run_test readonly-rootfs-cgo test_readonly_rootfs_cgo
    else
        skip "read-only rootfs tests disabled"
    fi

    run_test network-git-lsremote test_network_git_lsremote
    run_test network-go-module-download test_network_go_module_download
    run_test network-go-install-to-gopath-bin test_network_go_install_to_gopath_bin

    run_test reference-compare-env test_reference_compare_env_if_available
    run_test reference-compare-paths test_reference_compare_paths_if_available
    run_test reference-compare-config test_reference_compare_config_if_available
    run_test reference-compare-go-env test_reference_compare_go_env_if_available

    run_test slow-stdlib-smoke test_slow_stdlib_smoke

    echo
    echo "============================================================"
    echo "NiceOS Golang strict Bitnami-compatibility test summary"
    echo "============================================================"
    echo "Image:        ${IMAGE}"
    echo "Results dir:  ${RESULTS_DIR}"
    echo "Passed:       ${PASSED}"
    echo "Failed:       ${FAILED}"
    echo "Skipped:      ${SKIPPED}"
    echo "============================================================"

    if [ "${FAILED}" -ne 0 ]; then
        echo "FAILED: ${FAILED} test(s) failed" >&2
        exit 1
    fi

    echo "OK: all enabled tests passed"
}

main "$@"
