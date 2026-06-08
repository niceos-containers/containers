# NiceOS Application Containers

Public monorepo for NiceOS Application Containers.

NiceOS Application Containers are free, RPM-based, glibc-based application images built on the NiceOS.Container stream. The goal is to provide familiar application images and Bitnami-compatible migration targets while replacing Debian/minideb/apt/Stacksmith internals with NiceOS RPM packages and reproducible NiceOS build pipelines.

## Published images

| App | Docker Hub | GHCR | Runtime | Compatibility reference |
|---|---|---|---|---|
| NiceOS Git | `docker.io/niceos/git:2.54.0-niceos13-r2` | `ghcr.io/niceos-containers/git:2.54.0-niceos13-r2` | Git 2.54.0 + Git LFS 3.7.1 | `bitnami/git/2/debian-12` |
| NiceOS Golang | `docker.io/niceos/golang:1.26.4-niceos13-r1` | `ghcr.io/niceos-containers/golang:1.26.4-niceos13-r1` | Go 1.26.4 | `bitnami/golang/1.26/debian-12` |

## Quick start

For production, prefer immutable tags or digest-pinned references instead of `latest`.

### NiceOS Git

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r2 git --version
docker run --rm ghcr.io/niceos-containers/git:2.54.0-niceos13-r2 git --version
```

### NiceOS Golang

```console
docker run --rm docker.io/niceos/golang:1.26.4-niceos13-r1 go version
docker run --rm ghcr.io/niceos-containers/golang:1.26.4-niceos13-r1 go version
```

## Current image digests

| App | Docker Hub digest | GHCR digest |
|---|---|---|
| NiceOS Git | `docker.io/niceos/git@sha256:612d39a6aa268a379e938bf7695d312b78ea7e522ead5779ce9ee5e0216fba0d` | `ghcr.io/niceos-containers/git@sha256:612d39a6aa268a379e938bf7695d312b78ea7e522ead5779ce9ee5e0216fba0d` |
| NiceOS Golang | `docker.io/niceos/golang@sha256:716f8132ddb5cb919f24b9eb77859136e6d813adbf171e52bf17fe6f9ade4556` | `ghcr.io/niceos-containers/golang@sha256:716f8132ddb5cb919f24b9eb77859136e6d813adbf171e52bf17fe6f9ade4556` |

## Public catalog

The generated catalog is stored in:

```text
catalog/apps.yaml
```

Currently published apps:

- `git`: `docker.io/niceos/git:2.54.0-niceos13-r2` / `ghcr.io/niceos-containers/git:2.54.0-niceos13-r2`
- `golang`: `docker.io/niceos/golang:1.26.4-niceos13-r1` / `ghcr.io/niceos-containers/golang:1.26.4-niceos13-r1`

## Monorepo release policy

This repository is a public monorepo. Git tags point to a commit of the entire repository, not to a single app directory. The released artifact for each app is the OCI image tag and digest recorded in `catalog/apps.yaml` and `apps/<app>/RELEASE.yaml`.

## Repository layout

```text
apps/
  git/        NiceOS Git application container
  golang/        NiceOS Golang application container
catalog/
  apps.yaml   Public application catalog generated from apps/* metadata
docs/         Project documentation, when enabled
```

## Principles

- Free and open source application images.
- NiceOS.Container based runtime.
- RPM-controlled package provenance.
- glibc-based familiar Linux userland.
- Bitnami-compatible runtime contracts where migration requires them.
- Arbitrary UID support.
- Read-only root filesystem friendly.
- No package manager in final runtime images.
- No build tools in final runtime images.

## Source of truth

Primary development happens on NiceOS infrastructure. This GitHub repository is a public monorepo mirror and discovery point.

Public monorepo:

```text
https://github.com/niceos-containers/containers
```

## License

Repository integration files are licensed under Apache-2.0 unless stated otherwise. Container images include software under their respective upstream open source licenses.
