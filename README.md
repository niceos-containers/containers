# NiceOS Application Containers

Public monorepo for NiceOS Application Containers.

NiceOS Application Containers are free, RPM-based, glibc-based application images built on the NiceOS.Container stream. The goal is to provide familiar application images and Bitnami-compatible migration targets while replacing Debian/minideb/apt/Stacksmith internals with NiceOS RPM packages and reproducible NiceOS build pipelines.

## Published images

| App | Docker Hub | GHCR | Status | Runtime | Compatibility |
|---|---|---|---:|---|---|
| Git | `docker.io/niceos/git` | `ghcr.io/niceos-containers/git` | Published | Git 2.54.0 + Git LFS 3.7.1 | Bitnami-compatible migration target |

## Quick start

```console
docker run --rm docker.io/niceos/git:latest git --version
```

GHCR mirror:

```console
docker run --rm ghcr.io/niceos-containers/git:latest git --version
```

For production, prefer immutable tags or digest-pinned references:

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r1 git --version
docker run --rm ghcr.io/niceos-containers/git:2.54.0-niceos13-r1 git --version
```

## Current Git image digests

- Docker Hub: `docker.io/niceos/git@sha256:0e03b23aed2da4bc7e10de3160781c83ff88c8e9285963f68f83e693b60be790`
- GHCR: `ghcr.io/niceos-containers/git@sha256:0e03b23aed2da4bc7e10de3160781c83ff88c8e9285963f68f83e693b60be790`

## Monorepo release policy

This repository is a public monorepo. Git tags point to a commit of the entire repository, not to a single app directory. The released artifact for each app is the OCI image tag and digest recorded in `catalog/apps.yaml` and `apps/<app>/RELEASE.yaml`.

## Repository layout

```text
apps/
  git/        NiceOS Git application container
catalog/
  apps.yaml   Public application catalog
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

## Images

Docker Hub:

```text
docker.io/niceos/git:2.54.0-niceos13-r1
docker.io/niceos/git:2.54.0
docker.io/niceos/git:latest
```

GitHub Container Registry:

```text
ghcr.io/niceos-containers/git:2.54.0-niceos13-r1
ghcr.io/niceos-containers/git:2.54.0
ghcr.io/niceos-containers/git:latest
```

## Source of truth

Primary development happens on NiceOS infrastructure:

```text
https://specs.niceos.ru/niceos-containers/app-git
```

Public app path:

```text
https://github.com/niceos-containers/containers/tree/main/apps/git
```

Latest app metadata commit mirrored here:

```text
16c930c6de2bf70204334e0ba3be8c98ac6a1dab
```

## License

Repository integration files are licensed under Apache-2.0 unless stated otherwise. Container images include software under their respective upstream open source licenses.
