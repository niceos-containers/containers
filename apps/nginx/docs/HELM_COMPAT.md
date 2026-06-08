# Helm compatibility notes

This image is intended to be used as a Bitnami-compatible migration target for charts and manifests that previously used `bitnami/nginx`.

## Recommended override

```yaml
image:
  registry: docker.io
  repository: niceos/nginx
  tag: 1.31.1-niceos13-r1
```

For GHCR:

```yaml
image:
  registry: ghcr.io
  repository: niceos-containers/nginx
  tag: 1.31.1-niceos13-r1
```

## Preserved chart assumptions

- non-root default user `1001`;
- HTTP port `8080`;
- HTTPS port `8443`;
- `/app` static content directory;
- `/opt/bitnami/nginx/conf/server_blocks` custom server blocks;
- `/opt/bitnami/nginx/conf/context.d/*` custom context configuration directories;
- `/opt/bitnami/nginx/conf/stream_server_blocks` stream blocks when enabled;
- `/bitnami/nginx` compatibility persistence path;
- ENTRYPOINT and CMD scripts under `/opt/bitnami/scripts/nginx`.

## Important difference

The image is built from NiceOS.Container RPMs and does not contain Debian/minideb/apt/Stacksmith build internals.
