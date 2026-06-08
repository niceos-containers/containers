# Testing

## Smoke test

```console
./tests/smoke.sh docker.io/niceos/nginx-exporter:1.5.1-niceos13-r1
```

Checks:

- `--version` works;
- default entrypoint can start the exporter;
- `/metrics` responds on `9113`;
- the response contains exporter/NGINX metrics.

## Bitnami contract smoke test

```console
./tests/bitnami-contract-smoke.sh docker.io/niceos/nginx-exporter:1.5.1-niceos13-r1
```

Checks:

- UID `1001`;
- command paths;
- `/opt/bitnami` layout;
- `APP_VERSION`, `BITNAMI_APP_NAME`, `IMAGE_REVISION`;
- absence of package managers and build tools.

## Local compatibility suite

```console
./tests/local-compat-suite.sh docker.io/niceos/nginx-exporter:1.5.1-niceos13-r1
```

Adds:

- arbitrary UID run;
- read-only rootfs run;
- optional pod-level scrape against `docker.io/niceos/nginx` when the image is available locally or can be pulled.

## Compare with Bitnami

```console
BITNAMI_IMAGE=docker.io/bitnami/nginx-exporter:1.5.1 \
./tests/compare-with-bitnami.sh docker.io/niceos/nginx-exporter:1.5.1-niceos13-r1
```

The current Bitnami Secure Images may require entitlement, so the script skips gracefully if the reference image cannot be pulled.
