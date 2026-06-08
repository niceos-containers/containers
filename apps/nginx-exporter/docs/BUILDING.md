# Building NiceOS nginx-exporter

## Requirements

- NiceOS.Container base image: `docker.io/niceos/niceos-container-base:13`
- NiceOS.Container RPM repository containing `nginx-prometheus-exporter`
- `podman` or Docker-compatible engine
- `bash`
- `curl` or `wget` for tests

## Build

```console
make build
```

Equivalent explicit command:

```console
podman build --format docker --no-cache \
  --build-arg NICEOS_VERSION=13 \
  --build-arg APP_VERSION=1.5.1 \
  --build-arg IMAGE_REVISION=1 \
  -t docker.io/niceos/nginx-exporter:1.5.1-niceos13-r1 \
  -t docker.io/niceos/nginx-exporter:1.5.1 \
  -t docker.io/niceos/nginx-exporter:latest .
```

## RPM package name override

The Dockerfile defaults to:

```text
nginx-prometheus-exporter
```

If the ContainerSpecs package is named differently:

```console
podman build \
  --build-arg NICEOS_EXPORTER_PACKAGE=nginx-exporter \
  -t docker.io/niceos/nginx-exporter:1.5.1-niceos13-r1 .
```

## Final image policy

The final runtime image is built using a multi-stage installroot and `FROM scratch`. The final filesystem must not contain:

- `tdnf`, `dnf`, `yum`, `microdnf`;
- `rpm`, `rpmbuild`, RPM database;
- `gcc`, `go`, `make`, `cmake`, `ninja`;
- package-manager caches;
- systemd;
- unnecessary documentation/man/info pages.

## Version policy

- Immutable image tag: `<appVersion>-niceos<NiceOS.Container stream>-r<imageRevision>`
- Example: `1.5.1-niceos13-r1`
- Version tag: `1.5.1`
- Convenience tag: `latest`

Production documentation should recommend immutable tags or digest-pinned references.
