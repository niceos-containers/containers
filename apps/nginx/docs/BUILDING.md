# Building NiceOS NGINX

## Local build

```console
make build
```

Equivalent manual command:

```console
podman build --format docker --no-cache   --build-arg NICEOS_BASE_IMAGE=docker.io/niceosapps/niceos-container-base:13   --build-arg NICEOS_VERSION=13   --build-arg APP_VERSION=1.31.1   --build-arg IMAGE_REVISION=1   -t docker.io/niceos/nginx:1.31.1-niceos13-r1   -t docker.io/niceos/nginx:1.31.1   -t docker.io/niceos/nginx:latest .
```

## Expected RPM inputs

The Dockerfile expects a NiceOS.Container repository with these runtime/build packages or equivalent names:

```text
nginx
ca-certificates
openssl
nss_wrapper
shadow
coreutils
bash
grep
sed
findutils
gettext
procps
niceos-bitnami-compat-scripts
niceos-bitnami-compat-render-template
```

If the package names differ in ContainerSpecs, adjust `NICEOS_APP_PACKAGES` in the Dockerfile only. Do not change the runtime paths unless the compatibility contract is intentionally revised.

## Build graph

```text
NiceOS.Container RPM repo
  -> niceos-container-base
  -> app-nginx Dockerfile buildroot
  -> scratch final runtime image
  -> docker.io/niceos/nginx:1.31.1-niceos13-r1
  -> ghcr.io/niceos-containers/nginx:1.31.1-niceos13-r1
  -> monorepo apps/nginx + catalog/apps.yaml
```
