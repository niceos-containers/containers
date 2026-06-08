# NiceOS Golang Container

> A NiceOS.Container based Golang builder image with a strict Bitnami-compatible Docker command and workspace contract for migration from historical `bitnami/golang` workflows.

`docker.io/niceos/golang` provides Go 1.26 on the NiceOS.Container RPM/glibc base. It keeps the operational pieces commonly expected from `bitnami/golang`, while replacing Debian/minideb/apt/Stacksmith internals with NiceOS RPM packages and a reproducible NiceOS root filesystem.

This image is not an official Bitnami image and is not endorsed by Bitnami, Broadcom, VMware, or the Go project. It is a NiceSOFT/NiceOS compatibility target intended to help users migrate CI jobs, build pipelines and container workflows that expect the historical Bitnami Golang layout.

---

## TL;DR

Show Go version:

```console
docker run --rm docker.io/niceos/golang:1.26.4-niceos13-r1 go version
```

Run an interactive shell:

```console
docker run --rm -it docker.io/niceos/golang:1.26.4-niceos13-r1
```

Run a mounted project:

```console
docker run --rm -it \
  -v "$PWD:/go/src/project" \
  docker.io/niceos/golang:1.26.4-niceos13-r1 \
  bash -lc 'cd /go/src/project && go test ./...'
```

Build with cgo:

```console
docker run --rm -it \
  -v "$PWD:/go/src/project" \
  docker.io/niceos/golang:1.26.4-niceos13-r1 \
  bash -lc 'cd /go/src/project && CGO_ENABLED=1 go build ./...'
```

Run as arbitrary UID:

```console
docker run --rm \
  --user 12345:0 \
  docker.io/niceos/golang:1.26.4-niceos13-r1 \
  bash -lc 'id && go version && go env GOPATH'
```

Run with a read-only root filesystem:

```console
docker run --rm \
  --user 1001:0 \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --read-only \
  --tmpfs /tmp:rw,exec,nosuid,nodev \
  --tmpfs /var/tmp:rw,exec,nosuid,nodev \
  --tmpfs /run:rw,nosuid,nodev \
  --tmpfs /go:rw,exec,nosuid,nodev \
  docker.io/niceos/golang:1.26.4-niceos13-r1 \
  bash -lc 'go version && go env GOPATH'
```

---

## Strict Bitnami-compatible Docker contract

Unlike daemon-style Bitnami images, `bitnami/golang` is a builder/workspace image. The historical Docker contract is intentionally simple:

```text
ENTRYPOINT: none
USER:       none, therefore default user is root
CMD:        ["bash"]
WORKDIR:    /go
```

NiceOS follows that model for `golang`:

```console
docker inspect docker.io/niceos/golang:1.26.4-niceos13-r1 \
  --format 'User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}} Cmd={{json .Config.Cmd}} Workdir={{.Config.WorkingDir}}'
```

Expected:

```text
User= Entrypoint=null Cmd=["bash"] Workdir=/go
```

or an equivalent empty entrypoint representation.

There is deliberately no configured Docker `ENTRYPOINT` for this image. User commands run directly.

---

## Included software

| Component | Version | Source |
|---|---:|---|
| NiceOS.Container | 13 | NiceOS.Container RPM stream |
| Go | 1.26.4 | NiceOS `go1.26` RPM |
| GCC | 15.2.0 | NiceOS RPM |
| glibc | 2.43 | NiceOS RPM |
| linux-api-headers | 6.18.10 | NiceOS RPM |
| Git | 2.54.0 | NiceOS RPM |
| curl | 8.20.0 | NiceOS RPM |
| OpenSSL runtime | 3.6.1 | NiceOS RPM |

The image uses NiceOS RPM packages during image assembly and removes package manager commands from the final runtime image.

---

## Runtime layout

Important paths:

```text
/go
/go/src
/go/bin
/go/pkg
/go/.cache
/opt/bitnami/go
/opt/bitnami/go/bin/go
/opt/bitnami/go/bin/gofmt
/bitnami/golang
/etc/profile.d/00-bitnami-go-path.sh
/etc/profile.d/10-go-env.sh
```

Expected command resolution:

```console
docker run --rm docker.io/niceos/golang:1.26.4-niceos13-r1 command -v go
```

Expected:

```text
/opt/bitnami/go/bin/go
```

---

## Environment variables

| Variable | Value | Purpose |
|---|---|---|
| `APP_VERSION` | `1.26.4` | Go application/toolchain version |
| `BITNAMI_APP_NAME` | `golang` | Bitnami-style app identifier |
| `GOPATH` | `/go` | Default Go workspace |
| `GOCACHE` | `/go/.cache` | Default Go build cache |
| `GOMODCACHE` | `/go/pkg/mod` | Default module cache |
| `GOROOT` | `/opt/bitnami/go` | External compatibility path to Go root |
| `HOME` | `/go` | Builder-friendly home |
| `IMAGE_REVISION` | `1` | NiceOS image revision |
| `OS_ARCH` | build target arch | Architecture marker |
| `OS_FLAVOUR` | `niceos-container-13` | NiceOS.Container stream marker |
| `OS_NAME` | `linux` | OS family marker |
| `PATH` | `/go/bin:/opt/bitnami/go/bin:...` | Builder command lookup |

---

## Go modules

```console
docker run --rm docker.io/niceos/golang:1.26.4-niceos13-r1 bash -lc '
mkdir -p /go/src/demo
cd /go/src/demo
go mod init example.com/demo
cat > main.go <<EOF
package main
import "fmt"
func main(){ fmt.Println("hello from niceos") }
EOF
go run .
'
```

---

## cgo

This image intentionally includes the C toolchain pieces needed by Go builder workflows:

```text
gcc
binutils
make
pkgconf
glibc-devel
linux-api-headers
libgcc runtime/linker support
```

Example:

```console
docker run --rm docker.io/niceos/golang:1.26.4-niceos13-r1 bash -lc '
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
    fmt.Println("niceos-cgo-ok")
}
EOF

CGO_ENABLED=1 go run /tmp/cgo.go
'
```

Expected:

```text
niceos-cgo-ok
```

---

## Volumes

Common mounts:

| Host path | Container path | Purpose |
|---|---|---|
| project directory | `/go/src/project` | Source code |
| module cache | `/go/pkg/mod` | Optional module cache |
| build cache | `/go/.cache` | Optional Go build cache |
| persistent data | `/bitnami/golang` | Compatibility volume |

For host bind mounts with non-root users, make sure the host directory is writable by the selected UID/GID or use a Kubernetes `fsGroup`/volume policy.

---

## Security posture

The final image removes:

```text
tdnf
dnf
yum
rpm
rpm2cpio
repository metadata
package manager caches
setuid/setgid bits
manual/info/doc payloads
```

The image keeps GCC and build tools intentionally because this is a Go builder image. Small final runtime images for Go applications should be built with a multi-stage pattern.

---

## Validation

Local compatibility tests:

```console
IMAGE=docker.io/niceos/golang:1.26.4-niceos13-r1 \
APP_VERSION_EXPECTED=1.26.4 \
NICEOS_STREAM_EXPECTED=13 \
./tests/bitnami-compat-max.sh
```

Network tests:

```console
IMAGE=docker.io/niceos/golang:1.26.4-niceos13-r1 \
APP_VERSION_EXPECTED=1.26.4 \
NICEOS_STREAM_EXPECTED=13 \
RUN_NETWORK_TESTS=1 \
./tests/bitnami-compat-max.sh
```

Reference comparison:

```console
IMAGE=docker.io/niceos/golang:1.26.4-niceos13-r1 \
REF_IMAGE=bitnami/golang:1.26.4 \
APP_VERSION_EXPECTED=1.26.4 \
NICEOS_STREAM_EXPECTED=13 \
RUN_NETWORK_TESTS=1 \
./tests/bitnami-compat-max.sh
```

Expected release gate:

```text
Failed: 0
```

---

## License

Repository integration files are licensed under Apache-2.0 unless stated otherwise. Container images include software under their respective upstream open source licenses.
