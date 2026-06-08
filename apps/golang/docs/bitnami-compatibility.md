# Bitnami compatibility notes for NiceOS Golang

`bitnami/golang` is a builder/workspace image, not a daemon-style application
image. For this reason, the strict compatibility target is different from images
such as nginx, redis or postgresql.

## Strict Docker command contract

Expected Docker config:

```text
ENTRYPOINT: none
USER:       none
CMD:        ["bash"]
WORKDIR:    /go
```

NiceOS Golang intentionally follows this model.

## Why no ENTRYPOINT?

An active entrypoint changes command semantics. For example:

```console
docker run --rm image go version
```

should execute `go version` directly, not:

```text
/opt/bitnami/scripts/golang/entrypoint.sh go version
```

For `golang`, the safest compatibility mode is no configured Docker entrypoint.

## Why default root?

The historical `bitnami/golang` Dockerfile does not configure a Docker `USER`.
The default user is therefore root. NiceOS follows that behavior for maximum CI
and bind-mount compatibility.

Hardened execution is still supported explicitly:

```console
docker run --rm --user 1001:0 docker.io/niceos/golang:1.26.4-niceos13-r1 go version
```

## NiceOS compatibility-plus

NiceOS adds:

- RPM/glibc provenance
- `GOROOT=/opt/bitnami/go`
- cgo-capable toolchain
- arbitrary UID support when explicitly requested
- read-only rootfs compatibility with tmpfs mounts
- package manager removal from the final image
