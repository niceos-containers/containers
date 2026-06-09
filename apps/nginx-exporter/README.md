# NiceOS NGINX Prometheus Exporter Container

> A NiceOS.Container based `nginx-prometheus-exporter` image with the runtime contract expected by the Bitnami `nginx-exporter` image and by the Bitnami/NiceOS NGINX Helm chart metrics sidecar.

`docker.io/niceos/nginx-exporter` is a small RPM/glibc-based application container built from the separate NiceOS.Container stream. It is intended as a free, reproducible, NiceOS-native, Bitnami-compatible migration target for chart values and Kubernetes deployments that expect the historical Bitnami `nginx-exporter` image behavior.

This image is **not** an official Bitnami image and is not endorsed by Bitnami, Broadcom, VMware, F5, NGINX, or the NGINX project. Bitnami sources are used only as an Apache-2.0 compatibility reference. NiceOS replaces Debian/minideb/apt/Stacksmith internals with RPM-controlled NiceOS.Container packages.

---

## TL;DR

Run exporter with default scrape settings:

```console
docker run --rm -p 9113:9113 docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2
```

Run against a local NGINX stub status endpoint:

```console
docker run --rm -p 9113:9113 docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2 \
  --nginx.scrape-uri=http://127.0.0.1:8080/status
```

Run as a Bitnami/NiceOS NGINX chart metrics sidecar command:

```console
docker run --rm -p 9113:9113 --entrypoint exporter docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2 \
  --nginx.scrape-uri=http://127.0.0.1:8080/status
```

Run with a read-only root filesystem and arbitrary UID:

```console
docker run --rm \
  --user 12345:0 \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --read-only \
  --tmpfs /tmp:rw,nosuid,nodev \
  --tmpfs /var/tmp:rw,nosuid,nodev \
  -p 9113:9113 \
  docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2 \
  --web.listen-address=:9113 \
  --nginx.scrape-uri=http://127.0.0.1:8080/status
```

---

## Compatibility goal

The goal is not to copy Bitnami internals. For `nginx-exporter`, the Bitnami image is intentionally simple: it exposes the exporter binary directly as the image entrypoint, preserves a Bitnami-style `/opt/bitnami/nginx-exporter/bin` path, and creates the `exporter` compatibility command used by Bitnami charts.

| Contract area | NiceOS status |
|---|---|
| `/opt/bitnami` root | preserved |
| `/opt/bitnami/nginx-exporter` | preserved |
| `/opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter` | preserved as compatibility command path |
| `/usr/bin/exporter` | preserved as chart command alias |
| `nginx-prometheus-exporter` in `PATH` | preserved |
| default user `1001` | preserved |
| exposed port `9113` | preserved |
| `APP_VERSION` | preserved |
| `BITNAMI_APP_NAME=nginx-exporter` | preserved |
| `IMAGE_REVISION` | preserved |
| `WORKDIR=/opt/bitnami/nginx-exporter` | preserved |
| package manager in final image | removed |
| build tools in final image | removed |
| Debian/minideb/apt/Stacksmith | replaced by NiceOS/RPM |

---

## Image tags

Immutable tag:

```text
docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2
ghcr.io/niceos-containers/nginx-exporter:1.5.1-niceos13-r2
```

Version tag:

```text
docker.io/niceos/nginx-exporter:1.5.1
ghcr.io/niceos-containers/nginx-exporter:1.5.1
```

Convenience channel:

```text
docker.io/niceos/nginx-exporter:latest
ghcr.io/niceos-containers/nginx-exporter:latest
```

For production, prefer immutable tags or digest-pinned references.

---

## Included software

| Component | Version/source |
|---|---|
| NiceOS.Container | 13 RPM stream |
| NGINX Prometheus Exporter | 1.5.1 from NiceOS `nginx-prometheus-exporter` RPM |
| CA certificates | NiceOS RPM |
| bash/coreutils/procps-ng | NiceOS RPMs, kept minimal for chart compatibility and diagnostics |

---

## Runtime layout

```text
/opt/bitnami
/opt/bitnami/nginx-exporter
/opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter
/opt/bitnami/scripts/nginx-exporter/entrypoint.sh
/opt/bitnami/scripts/nginx-exporter/run.sh
/opt/bitnami/scripts/nginx-exporter-env.sh
/usr/bin/exporter -> /opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter
```

The default `ENTRYPOINT` remains the binary:

```text
nginx-prometheus-exporter
```

The wrapper scripts are present only for diagnostics and future NiceOS consistency. They are not used by default because the Bitnami reference image starts the binary directly.

---

## Environment variables

| Variable | Default | Purpose |
|---|---:|---|
| `APP_VERSION` | `1.5.1` | Exporter version marker |
| `IMAGE_REVISION` | `1` | NiceOS image revision |
| `BITNAMI_APP_NAME` | `nginx-exporter` | Bitnami-style app identifier |
| `BITNAMI_IMAGE_VERSION` | `1.5.1-niceos13-r2` | Bitnami-style image version marker |
| `BITNAMI_ROOT_DIR` | `/opt/bitnami` | Bitnami-style root |
| `NICEOS_CONTAINER_STREAM` | `13` | NiceOS.Container stream |
| `OS_FLAVOUR` | `niceos-container-13` | NiceOS OS flavour marker |
| `PATH` | `/opt/bitnami/nginx-exporter/bin:...` | Compatibility command path |

Exporter configuration is passed as command-line flags, for example:

```console
--web.listen-address=:9113
--web.telemetry-path=/metrics
--nginx.scrape-uri=http://127.0.0.1:8080/status
--nginx.plus=false
--log.level=info
```

---

## Helm chart usage

For the adapted NiceOS NGINX chart, enable metrics with:

```yaml
metrics:
  enabled: true
  image:
    registry: docker.io
    repository: niceos/nginx-exporter
    tag: 1.5.1-niceos13-r2
```

For strict compatibility with a chart release that still expects `1.4.2`, build and publish a legacy-compatible NiceOS tag:

```console
make build APP_VERSION=1.4.2 IMAGE_REVISION=1
make test APP_VERSION=1.4.2 IMAGE_REVISION=1
make push APP_VERSION=1.4.2 IMAGE_REVISION=1
```

Then use:

```yaml
metrics:
  enabled: true
  image:
    registry: docker.io
    repository: niceos/nginx-exporter
    tag: 1.5.1-niceos13-r2
```

---

## Building

```console
podman build --format docker --no-cache \
  --build-arg NICEOS_VERSION=13 \
  --build-arg APP_VERSION=1.5.1 \
  --build-arg IMAGE_REVISION=1 \
  -t docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2 \
  -t docker.io/niceos/nginx-exporter:1.5.1 \
  -t docker.io/niceos/nginx-exporter:latest .
```

Or:

```console
make build
```

If your RPM package name differs, pass it during build:

```console
podman build \
  --build-arg NICEOS_EXPORTER_PACKAGE=nginx-exporter \
  -t docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2 .
```

---

## Testing

```console
./tests/smoke.sh docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2
./tests/bitnami-contract-smoke.sh docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2
./tests/local-compat-suite.sh docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2
```

The tests check:

- binary entrypoint behavior;
- `nginx-prometheus-exporter` command;
- `exporter` command alias;
- `/opt/bitnami/nginx-exporter/bin` path;
- default non-root UID `1001`;
- arbitrary UID execution;
- read-only root filesystem behavior;
- metrics endpoint on `:9113`;
- absence of package managers and build tools in the final runtime image;
- compatibility with the NiceOS/Bitnami NGINX chart metrics sidecar pattern.

Optional chart rendering test:

```console
./tests/helm-nginx-chart-metrics-smoke.sh /DATA2/niceos-containers/chart-nginx/chart \
  docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2
```

---

## Release automation

```console
./scripts/niceos_app_release_nginx_exporter.py release 1.5.1 \
  --revision 1 \
  --niceos-version 13 \
  --app-repo /DATA2/niceos-containers/app-nginx-exporter \
  --monorepo /DATA2/github/niceos-containers/containers \
  -y
```

Metadata-only monorepo refresh:

```console
./scripts/niceos_app_release_nginx_exporter.py update 1.5.1 \
  --revision 1 \
  --niceos-version 13 \
  --refresh-monorepo-only \
  -y
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
│   ├── RPM.md
│   ├── SECURITY.md
│   ├── TESTING.md
│   └── releases
│       └── 1.5.1-niceos13-r2.md
├── packaging
│   └── rpm
│       ├── create-vendor-archive.sh
│       └── nginx-prometheus-exporter.spec
├── releases
│   └── 1.5.1-niceos13-r2.yaml
├── rootfs
│   ├── etc/profile.d/00-bitnami-nginx-exporter-path.sh
│   └── opt/bitnami
│       ├── nginx-exporter
│       └── scripts
│           ├── nginx-exporter
│           │   ├── entrypoint.sh
│           │   └── run.sh
│           └── nginx-exporter-env.sh
├── scripts
│   └── niceos_app_release_nginx_exporter.py
└── tests
    ├── bitnami-contract-smoke.sh
    ├── compare-with-bitnami.sh
    ├── helm-nginx-chart-metrics-smoke.sh
    ├── local-compat-suite.sh
    └── smoke.sh
```

---

## Registries

Docker Hub:

```text
docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2
docker.io/niceos/nginx-exporter:1.5.1
docker.io/niceos/nginx-exporter:latest
```

GitHub Container Registry:

```text
ghcr.io/niceos-containers/nginx-exporter:1.5.1-niceos13-r2
ghcr.io/niceos-containers/nginx-exporter:1.5.1
ghcr.io/niceos-containers/nginx-exporter:latest
```

<!-- niceos:app-nginx-exporter-registries:begin -->
## Registries

Docker Hub:

```text
docker.io/niceos/nginx-exporter:1.5.1-niceos13-r2
docker.io/niceos/nginx-exporter:1.5.1
docker.io/niceos/nginx-exporter:latest
```

GitHub Container Registry:

```text
ghcr.io/niceos-containers/nginx-exporter:1.5.1-niceos13-r2
ghcr.io/niceos-containers/nginx-exporter:1.5.1
ghcr.io/niceos-containers/nginx-exporter:latest
```

AWS ECR Public:

```text
public.ecr.aws/t5j6z0j2/nginx-exporter:1.5.1-niceos13-r2
public.ecr.aws/t5j6z0j2/nginx-exporter:1.5.1
public.ecr.aws/t5j6z0j2/nginx-exporter:latest
```

Digests:

- Digests are refreshed by release automation after image push.
<!-- niceos:app-nginx-exporter-registries:end -->
