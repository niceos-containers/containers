#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-docker.io/niceos/golang:1.26.4-niceos13-r1}"
CONTAINER_ENGINE="${CONTAINER_ENGINE:-podman}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

info() { printf '\n==> %s\n' "$*" >&2; }
run() { "${CONTAINER_ENGINE}" run --rm "$@"; }

info "image metadata"
"${CONTAINER_ENGINE}" image inspect "${IMAGE}" >/dev/null

info "go version and env"
run "${IMAGE}" bash -ec '
set -euo pipefail
go version
/opt/bitnami/go/bin/go version
test "$(go env GOPATH)" = "/go"
test "$(go env GOCACHE)" = "/go/.cache"
test "$(go env GOMODCACHE)" = "/go/pkg/mod"
case ":$PATH:" in *:/opt/bitnami/go/bin:*) ;; *) echo "missing /opt/bitnami/go/bin in PATH" >&2; exit 1 ;; esac
case ":$PATH:" in *:/go/bin:*) ;; *) echo "missing /go/bin in PATH" >&2; exit 1 ;; esac
'

info "bitnami-compatible paths"
run "${IMAGE}" bash -ec '
set -euo pipefail
test -d /go
test -d /go/src
test -d /go/bin
test -d /go/pkg
test -d /go/.cache
test -e /opt/bitnami/go
test -x /opt/bitnami/go/bin/go
test -x /opt/bitnami/scripts/golang/entrypoint.sh
test -x /opt/bitnami/scripts/golang/setup.sh
'

info "hello world go run"
cat > "${WORKDIR}/hello.go" <<'EOF'
package main
import "fmt"
func main() { fmt.Println("hello from NiceOS Golang") }
EOF
run -v "${WORKDIR}:/go/src/project:Z" -w /go/src/project "${IMAGE}" bash -ec 'go run ./hello.go | grep "hello from NiceOS Golang"'

info "go module workflow"
cat > "${WORKDIR}/go.mod" <<'EOF'
module example.com/niceos-golang-smoke

go 1.26
EOF
cat > "${WORKDIR}/main.go" <<'EOF'
package main
import "fmt"
func main() { fmt.Println("module smoke") }
EOF
run -v "${WORKDIR}:/go/src/project:Z" -w /go/src/project "${IMAGE}" bash -ec 'go list ./... && go run . | grep "module smoke"'

info "cgo compile smoke"
cat > "${WORKDIR}/cgo.go" <<'EOF'
package main
/*
#include <stdio.h>
*/
import "C"
func main() { C.puts(C.CString("cgo smoke")) }
EOF
run -v "${WORKDIR}:/go/src/project:Z" -w /go/src/project "${IMAGE}" bash -ec 'CGO_ENABLED=1 go build -o /tmp/cgo-smoke ./cgo.go && /tmp/cgo-smoke | grep "cgo smoke"'

info "arbitrary uid"
run --user 12345:0 "${IMAGE}" bash -ec '
set -euo pipefail
id
test "$(id -u)" = "12345"
test "$(go env GOPATH)" = "/go"
cat > /go/uid.go <<EOF
package main
func main(){}
EOF
go run /go/uid.go
'

info "read-only rootfs"
run \
  --user 12345:0 \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --read-only \
  --tmpfs /tmp:rw,exec,nosuid,nodev \
  --tmpfs /var/tmp:rw,exec,nosuid,nodev \
  --tmpfs /run:rw,nosuid,nodev \
  --tmpfs /go:rw,exec,nosuid,nodev \
  "${IMAGE}" bash -ec '
set -euo pipefail
go version
cat > /go/ro.go <<EOF
package main
import "fmt"
func main(){fmt.Println("readonly ok")}
EOF
go run /go/ro.go | grep "readonly ok"
'

info "forbidden package managers are absent"
run "${IMAGE}" bash -ec '
set -euo pipefail
for cmd in tdnf dnf yum rpm; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "forbidden command present: $cmd" >&2
    exit 1
  fi
done
'

info "all tests passed for ${IMAGE}"
