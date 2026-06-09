# NiceOS Application Containers

Public monorepo for NiceOS Application Containers.

NiceOS Application Containers are free, RPM-based, glibc-based application images built on the NiceOS.Container stream. The goal is to provide familiar application images and Bitnami-compatible migration targets while replacing Debian/minideb/apt/Stacksmith internals with NiceOS RPM packages and reproducible NiceOS build pipelines.

## Published images

| App | Docker Hub | GHCR | AWS ECR Public | Runtime | Compatibility reference |
|---|---|---|---|---|---|
| NiceOS Git | `docker.io/niceos/git:2.54.0-niceos13-r2` | `ghcr.io/niceos-containers/git:2.54.0-niceos13-r2` | `pending` | Git 2.54.0 + Git LFS 3.7.1 | `bitnami/git/2/debian-12` |
| NiceOS Golang | `docker.io/niceos/golang:1.26.4-niceos13-r1` | `ghcr.io/niceos-containers/golang:1.26.4-niceos13-r1` | `pending` | Golang 1.26.4 | `bitnami/golang/1.26/debian-12` |
| NiceOS NGINX | `docker.io/niceos/nginx:1.31.1-niceos13-r1` | `ghcr.io/niceos-containers/nginx:1.31.1-niceos13-r1` | `pending` | NGINX 1.31.1 + njs 0.9.9 + headers-more 0.39 | `bitnami/nginx/1.31/debian-12` |
| NiceOS NGINX Exporter | `docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2` | `ghcr.io/niceos-containers/nginx-exporter:1.5.1-niceos13-r2` | `public.ecr.aws/t5j6z0j2/nginx-exporter:1.5.1-niceos13-r2` | Nginx Exporter 1.5.1 | `bitnami/nginx-exporter/1/debian-12` |

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

### NiceOS NGINX

```console
docker run --rm docker.io/niceos/nginx:1.31.1-niceos13-r1 nginx -v
docker run --rm ghcr.io/niceos-containers/nginx:1.31.1-niceos13-r1 nginx -v

```

### NiceOS NGINX Exporter

```console
docker run --rm docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2 nginx-exporter --version
docker run --rm ghcr.io/niceos-containers/nginx-exporter:1.5.1-niceos13-r2 nginx-exporter --version
docker run --rm public.ecr.aws/t5j6z0j2/nginx-exporter:1.5.1-niceos13-r2 nginx-exporter --version
```

## Current image digests

| App | Docker Hub digest | GHCR digest | AWS ECR Public digest |
|---|---|---|---|
| NiceOS Git | `docker.io/niceos/git@sha256:612d39a6aa268a379e938bf7695d312b78ea7e522ead5779ce9ee5e0216fba0d` | `ghcr.io/niceos-containers/git@sha256:612d39a6aa268a379e938bf7695d312b78ea7e522ead5779ce9ee5e0216fba0d` | `pending` |
| NiceOS Golang | `docker.io/niceos/golang@sha256:716f8132ddb5cb919f24b9eb77859136e6d813adbf171e52bf17fe6f9ade4556` | `ghcr.io/niceos-containers/golang@sha256:716f8132ddb5cb919f24b9eb77859136e6d813adbf171e52bf17fe6f9ade4556` | `pending` |
| NiceOS NGINX | `docker.io/niceos/nginx@sha256:427debcf5802bbca860409681429a91ece24f91f35e0c11252ab67bd29f3358f` | `ghcr.io/niceos-containers/nginx@sha256:427debcf5802bbca860409681429a91ece24f91f35e0c11252ab67bd29f3358f` | `pending` |
| NiceOS NGINX Exporter | `docker.io/niceos/nginx-exporter@pending` | `ghcr.io/niceos-containers/nginx-exporter@pending` | `public.ecr.aws/t5j6z0j2/nginx-exporter@pending` |

## Public catalog

The generated catalog is stored in:

```text
catalog/apps.yaml
```

Currently published apps:

- `git`: `docker.io/niceos/git:2.54.0-niceos13-r2` / `ghcr.io/niceos-containers/git:2.54.0-niceos13-r2`
- `golang`: `docker.io/niceos/golang:1.26.4-niceos13-r1` / `ghcr.io/niceos-containers/golang:1.26.4-niceos13-r1`
- `nginx`: `docker.io/niceos/nginx:1.31.1-niceos13-r1` / `ghcr.io/niceos-containers/nginx:1.31.1-niceos13-r1`
- `nginx-exporter`: `docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2` / `ghcr.io/niceos-containers/nginx-exporter:1.5.1-niceos13-r2` / `public.ecr.aws/t5j6z0j2/nginx-exporter:1.5.1-niceos13-r2`

## Monorepo release policy

This repository is a public monorepo. Git tags point to a commit of the entire repository, not to a single app directory. The released artifact for each app is the OCI image tag and digest recorded in `catalog/apps.yaml` and `apps/<app>/RELEASE.yaml`.

## Repository layout

```text
apps/
  git/        NiceOS Git application container
  golang/        NiceOS Golang application container
  nginx/        NiceOS NGINX application container
  nginx-exporter/        NiceOS NGINX Exporter application container
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
