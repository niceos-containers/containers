# NiceOS NGINX Container

> A NiceOS.Container based NGINX Open Source image with a Bitnami-compatible runtime contract for migration from historical `bitnami/nginx` workflows and charts.

`docker.io/niceos/nginx` is an NGINX application container built on the NiceOS.Container RPM/glibc stream. It keeps the operational layout expected by Bitnami-style images while replacing Debian/minideb/apt/Stacksmith internals with NiceOS RPM packages and a reproducible NiceOS root filesystem.

This image is not an official Bitnami image and is not endorsed by Bitnami, Broadcom, VMware, F5, NGINX, or the NGINX project. It is a NiceSOFT/NiceOS compatibility target intended to help users migrate existing automation, Helm charts, CI jobs, and container workflows that expect the historical Bitnami runtime contract.

---

## TL;DR

```console
docker run --rm -p 8080:8080 docker.io/niceos/nginx:1.31.1-niceos13-r1
```

Run a shell:

```console
docker run --rm -it docker.io/niceos/nginx:1.31.1-niceos13-r1 /bin/bash
```

Serve a static directory:

```console
docker run --rm -p 8080:8080   -v "$PWD/site:/app:ro"   docker.io/niceos/nginx:1.31.1-niceos13-r1
```

Run with a custom server block:

```console
docker run --rm -p 8080:8080   -v "$PWD/my_server_block.conf:/opt/bitnami/nginx/conf/server_blocks/my_server_block.conf:ro"   docker.io/niceos/nginx:1.31.1-niceos13-r1
```

Run as arbitrary UID with read-only root filesystem:

```console
docker run --rm   --user 12345:0   --cap-drop ALL   --security-opt no-new-privileges   --read-only   --tmpfs /tmp:rw,exec,nosuid,nodev   --tmpfs /var/tmp:rw,exec,nosuid,nodev   --tmpfs /run:rw,nosuid,nodev   -p 8080:8080   docker.io/niceos/nginx:1.31.1-niceos13-r1
```

---

## Compatibility goal

The goal is not to copy Bitnami internals. The goal is to preserve the runtime contract that existing deployments commonly depend on:

| Contract area | NiceOS status |
|---|---|
| `/opt/bitnami` root | preserved |
| `/opt/bitnami/nginx` | preserved |
| `/opt/bitnami/nginx/sbin/nginx` | preserved as compatibility command path |
| `/opt/bitnami/nginx/conf` | preserved |
| `/opt/bitnami/nginx/conf.default` | preserved |
| `/opt/bitnami/nginx/conf/server_blocks` | preserved |
| `/opt/bitnami/nginx/conf/context.d/*` | preserved |
| `/opt/bitnami/nginx/conf/stream_server_blocks` | preserved |
| `/opt/bitnami/scripts/nginx/entrypoint.sh` | preserved |
| `/opt/bitnami/scripts/nginx/setup.sh` | preserved |
| `/opt/bitnami/scripts/nginx/run.sh` | preserved |
| `/app` static content directory | preserved |
| `/bitnami/nginx` persistence path | preserved |
| default user `1001` | preserved |
| exposed ports `8080` and `8443` | preserved |
| `NGINX_*` environment variables | preserved where relevant |
| package manager in final image | removed |
| Debian/minideb/apt/Stacksmith | replaced by NiceOS/RPM |

---

## Image tags

Immutable tag:

```text
docker.io/niceos/nginx:1.31.1-niceos13-r1
ghcr.io/niceos-containers/nginx:1.31.1-niceos13-r1
```

Version tag:

```text
docker.io/niceos/nginx:1.31.1
ghcr.io/niceos-containers/nginx:1.31.1
```

Convenience channel:

```text
docker.io/niceos/nginx:latest
ghcr.io/niceos-containers/nginx:latest
```

For production, prefer immutable tags or digest-pinned references.

---

## Included software

| Component | Version/source |
|---|---|
| NiceOS.Container | 13 RPM stream |
| NGINX | 1.31.1 from NiceOS `nginx` RPM |
| nss_wrapper | NiceOS RPM, exposed through `/opt/bitnami/common/lib/libnss_wrapper.so` |
| render-template | NiceOS compatibility RPM, exposed through `/opt/bitnami/common/bin/render-template` |
| CA certificates/OpenSSL | NiceOS RPMs |

---

## Runtime layout

```text
/opt/bitnami
/opt/bitnami/nginx
/opt/bitnami/nginx/sbin/nginx
/opt/bitnami/nginx/conf/nginx.conf
/opt/bitnami/nginx/conf.default/nginx.conf
/opt/bitnami/nginx/conf/server_blocks/default.conf
/opt/bitnami/nginx/conf/context.d/main
/opt/bitnami/nginx/conf/context.d/events
/opt/bitnami/nginx/conf/context.d/http
/opt/bitnami/nginx/conf/stream_server_blocks
/opt/bitnami/nginx/logs/access.log -> /dev/stdout
/opt/bitnami/nginx/logs/error.log  -> /dev/stderr
/opt/bitnami/scripts/nginx/entrypoint.sh
/opt/bitnami/scripts/nginx/setup.sh
/opt/bitnami/scripts/nginx/run.sh
/app
/bitnami/nginx
```

---

## Environment variables

| Variable | Default | Purpose |
|---|---:|---|
| `APP_VERSION` | `1.31.1` | NGINX version marker |
| `IMAGE_REVISION` | `1` | NiceOS image revision |
| `BITNAMI_APP_NAME` | `nginx` | Bitnami-style app identifier |
| `BITNAMI_ROOT_DIR` | `/opt/bitnami` | Bitnami-style root |
| `BITNAMI_VOLUME_DIR` | `/bitnami` | Bitnami-style volume root |
| `NGINX_HTTP_PORT_NUMBER` | `8080` | HTTP listen port for generated/default config |
| `NGINX_HTTPS_PORT_NUMBER` | `8443` | HTTPS listen port for generated/default config |
| `NGINX_WORKER_PROCESSES` | `auto` | Worker process setting |
| `NGINX_ENABLE_STREAM` | `no` | Enable stream context rendering when modules support it |
| `NGINX_ENABLE_ABSOLUTE_REDIRECT` | `no` | Render absolute redirects in default/server block helpers |
| `NGINX_ENABLE_PORT_IN_REDIRECT` | `no` | Include container listen port in redirects |
| `NSS_WRAPPER_LIB` | `/opt/bitnami/common/lib/libnss_wrapper.so` | arbitrary UID support |

---

## Building

```console
podman build --format docker --no-cache   --build-arg NICEOS_VERSION=13   --build-arg APP_VERSION=1.31.1   --build-arg IMAGE_REVISION=1   -t docker.io/niceos/nginx:1.31.1-niceos13-r1   -t docker.io/niceos/nginx:1.31.1   -t docker.io/niceos/nginx:latest .
```

Or:

```console
make build
```

---

## Testing

```console
./tests/smoke.sh docker.io/niceos/nginx:1.31.1-niceos13-r1
./tests/bitnami-contract-smoke.sh docker.io/niceos/nginx:1.31.1-niceos13-r1
./tests/local-compat-suite.sh docker.io/niceos/nginx:1.31.1-niceos13-r1
```

The tests check command paths, environment variables, non-root behavior, arbitrary UID behavior, read-only rootfs behavior, HTTP serving, NGINX config syntax, forbidden package-manager/build-tool absence, and the Bitnami-style runtime layout.

---

## Release automation

```console
./scripts/niceos_app_release_nginx.py release 1.31.1   --revision 1   --niceos-version 13   --app-repo /DATA2/niceos-containers/app-nginx   --monorepo /DATA2/github/niceos-containers/containers   -y
```

Metadata-only monorepo refresh:

```console
./scripts/niceos_app_release_nginx.py update 1.31.1   --revision 1   --niceos-version 13   --refresh-monorepo-only   -y
```

---

## Repository layout

```text
.
├── compat
│   ├── bitnami-reference.txt
│   └── contract.yaml
├── docs
│   ├── BUILDING.md
│   ├── HELM_COMPAT.md
│   └── releases
│       └── 1.31.1-niceos13-r1.md
├── rootfs
│   ├── app
│   │   └── index.html
│   ├── etc
│   │   └── profile.d
│   │       └── 00-bitnami-nginx-path.sh
│   └── opt
│       └── bitnami
│           ├── nginx
│           │   └── conf.default
│           │       ├── nginx.conf
│           │       └── server_blocks/default.conf
│           └── scripts
│               ├── libnginx.sh
│               ├── nginx-env.sh
│               └── nginx
│                   ├── bitnami-templates/default-https-server-block.conf
│                   ├── entrypoint.sh
│                   ├── postunpack.sh
│                   ├── run.sh
│                   └── setup.sh
├── scripts
│   └── niceos_app_release_nginx.py
└── tests
    ├── bitnami-contract-smoke.sh
    ├── compare-with-bitnami.sh
    ├── local-compat-suite.sh
    └── smoke.sh
```

<!-- niceos:app-nginx-registries:begin -->
## Registries

Docker Hub:

```text
docker.io/niceos/nginx:1.31.1-niceos13-r1
docker.io/niceos/nginx:1.31.1
docker.io/niceos/nginx:latest
```

GitHub Container Registry:

```text
ghcr.io/niceos-containers/nginx:1.31.1-niceos13-r1
ghcr.io/niceos-containers/nginx:1.31.1
ghcr.io/niceos-containers/nginx:latest
```

Digests:

- Docker Hub immutable digest: `docker.io/niceos/nginx@sha256:427debcf5802bbca860409681429a91ece24f91f35e0c11252ab67bd29f3358f`
- GHCR immutable digest: `ghcr.io/niceos-containers/nginx@sha256:427debcf5802bbca860409681429a91ece24f91f35e0c11252ab67bd29f3358f`
<!-- niceos:app-nginx-registries:end -->
