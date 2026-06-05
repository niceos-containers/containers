# NiceOS Git Container

> A NiceOS.Container based Git application image with a Bitnami-compatible runtime contract for migration from historical Bitnami-style Git containers and charts.

`docker.io/niceos/git` is a Git command-line container built on the NiceOS.Container stream. It preserves the operational layout expected by Bitnami-style images while replacing Debian/minideb/apt/Stacksmith internals with NiceOS RPM packages and a reproducible NiceOS root filesystem.

This image is not an official Bitnami image and is not endorsed by Bitnami, Broadcom, VMware, or the Git project. It is a NiceSOFT/NiceOS compatibility target intended to help users migrate existing automation, Helm charts, CI jobs, and container workflows that expect the historical Bitnami runtime contract.

---

## TL;DR

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r2 git --version
```

Run an interactive shell:

```console
docker run --rm -it docker.io/niceos/git:2.54.0-niceos13-r2
```

Clone a repository over HTTPS:

```console
docker run --rm -it \
  -v "$PWD/work:/work" \
  -w /work \
  docker.io/niceos/git:2.54.0-niceos13-r2 \
  git clone https://github.com/git/git.git
```

Run with an arbitrary non-root UID:

```console
docker run --rm \
  --user 12345:0 \
  docker.io/niceos/git:2.54.0-niceos13-r2 \
  /bin/bash -c 'id && getent passwd "$(id -u)" && git --version'
```

Run with a read-only root filesystem:

```console
docker run --rm \
  --user 12345:0 \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --read-only \
  --tmpfs /tmp:rw,exec,nosuid,nodev \
  --tmpfs /var/tmp:rw,exec,nosuid,nodev \
  --tmpfs /run:rw,nosuid,nodev \
  docker.io/niceos/git:2.54.0-niceos13-r2 \
  git --version
```

---

## Why use this image?

This image is designed for users who want the operational convenience of Bitnami-style application containers, but with a NiceOS/RPM-controlled base.

### NiceOS goals

- Preserve the historical Bitnami-style runtime layout where it matters.
- Keep application images reproducible and package-managed through NiceOS.Container RPMs.
- Avoid hidden Debian/minideb/apt/Stacksmith build internals in production images.
- Keep the runtime image small enough for practical CI/CD use, but not so minimal that common Git workflows break.
- Support arbitrary UID execution through `nss_wrapper`.
- Support read-only root filesystem scenarios.
- Keep Git LFS available for repositories that require it.
- Remove package managers and build tools from the final runtime image.
- Use ordinary `glibc`, OpenSSL, CA trust, OpenSSH client tools, and familiar Linux userland behavior.

### What this image is

This image is a **NiceOS-based Bitnami-compatible migration target**.

It preserves the parts of the Bitnami-style contract that existing charts, jobs, scripts, and user expectations commonly depend on:

- `/opt/bitnami`
- `/opt/bitnami/scripts`
- `/opt/bitnami/scripts/git/entrypoint.sh`
- `/opt/bitnami/git/bin`
- `/opt/bitnami/common/bin`
- `/opt/bitnami/common/lib/libnss_wrapper.so`
- `/bitnami/git`
- `BITNAMI_*` environment variables
- `NSS_WRAPPER_LIB`
- arbitrary UID support
- shell entrypoint behavior
- Git command lookup through `/opt/bitnami/git/bin`
- Git LFS filter configuration
- HTTPS and SSH Git workflows

### What this image is not

This image is not:

- an official Bitnami image;
- a copy of Bitnami Secure Images;
- a Debian/minideb based image;
- a generic OS container with package manager left inside;
- a Git server image with `sshd` enabled;
- a full development toolbox with compilers and build systems.

The final image intentionally removes package manager and build-time tooling from the runtime filesystem.

---

## Image variants and tags

Recommended immutable tag:

```text
docker.io/niceos/git:2.54.0-niceos13-r2
```

Convenience version tag:

```text
docker.io/niceos/git:2.54.0
```

Recommended future rolling tags, when enabled by release policy:

```text
docker.io/niceos/git:latest
docker.io/niceos/git:2
docker.io/niceos/git:2.54
```

For production, prefer immutable tags such as:

```text
2.54.0-niceos13-r2
```

### Tag meaning

```text
2.54.0-niceos13-r2
│      │        └── image revision
│      └────────── NiceOS.Container release stream
└───────────────── upstream Git application version
```

---

## Included software

| Component | Version | Source |
|---|---:|---|
| NiceOS.Container | 13 | NiceOS.Container RPM stream |
| Git | 2.54.0 | NiceOS `git` RPM |
| Git LFS | 3.7.1 | NiceOS `git-lfs` RPM |
| OpenSSH clients | 10.2p1 | NiceOS RPM |
| curl | 8.20.0 | NiceOS RPM |
| OpenSSL runtime | 3.6.1 | NiceOS RPM |
| glibc | 2.43 | NiceOS RPM |
| nss_wrapper | 1.1.16 | NiceOS RPM |
| Bitnami-compatible helper scripts | 20260605 | NiceOS RPM |

The image uses NiceOS RPM packages during image assembly and removes package manager commands from the final runtime image.

---

## Runtime layout

Important paths:

```text
/opt/bitnami
/opt/bitnami/git/bin
/opt/bitnami/common/bin
/opt/bitnami/common/lib/libnss_wrapper.so
/opt/bitnami/scripts
/opt/bitnami/scripts/git/entrypoint.sh
/bitnami/git
/etc/gitconfig
/etc/profile.d/00-bitnami-path.sh
```

Git commands are exposed through `/opt/bitnami/git/bin` as compatibility symlinks.

Expected command resolution:

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r2 command -v git
```

Expected output:

```text
/opt/bitnami/git/bin/git
```

Expected Git LFS command resolution:

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r2 command -v git-lfs
```

Expected output:

```text
/opt/bitnami/git/bin/git-lfs
```

---

## Environment variables

| Variable | Value | Purpose |
|---|---|---|
| `HOME` | `/` | Bitnami-compatible home for arbitrary UID runtime |
| `OS_ARCH` | build target arch | Architecture marker |
| `OS_FLAVOUR` | `niceos-container-13` | NiceOS.Container stream marker |
| `OS_NAME` | `linux` | OS family marker |
| `APP_VERSION` | `2.54.0` | Git application version |
| `IMAGE_REVISION` | `1` | NiceOS image revision |
| `BITNAMI_APP_NAME` | `git` | Bitnami-style app identifier |
| `BITNAMI_ROOT_DIR` | `/opt/bitnami` | Bitnami-style root directory |
| `BITNAMI_VOLUME_DIR` | `/bitnami` | Bitnami-style volume directory |
| `NSS_WRAPPER_LIB` | `/opt/bitnami/common/lib/libnss_wrapper.so` | Arbitrary UID support |
| `PATH` | `/opt/bitnami/git/bin:/opt/bitnami/common/bin:...` | Compatibility command lookup |

---

## Running commands

The container entrypoint prepares the compatibility runtime and then executes the requested command.

Show Git version:

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r2 git --version
```

Show Git LFS version:

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r2 git-lfs version
```

Run Bash:

```console
docker run --rm -it docker.io/niceos/git:2.54.0-niceos13-r2 /bin/bash
```

Run a login shell:

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r2 /bin/bash -lc 'echo "$PATH" && command -v git'
```

---

## Git over HTTPS

The image includes CA certificates and a deterministic system Git configuration:

```ini
[http]
    sslCAInfo = /etc/pki/tls/certs/ca-bundle.crt
    sslCAPath = /etc/ssl/certs
```

Example:

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r2 \
  git ls-remote https://github.com/git/git.git HEAD
```

---

## Git over SSH

The image includes OpenSSH client tools:

- `ssh`
- `ssh-keygen`
- `ssh-agent`
- `ssh-add`
- `scp`
- `sftp`

Example with a mounted private key:

```console
docker run --rm -it \
  -v "$HOME/.ssh:/ssh:ro" \
  -e GIT_SSH_COMMAND='ssh -i /ssh/id_ed25519 -o StrictHostKeyChecking=accept-new' \
  docker.io/niceos/git:2.54.0-niceos13-r2 \
  git ls-remote git@github.com:git/git.git HEAD
```

This image is not an SSH server image. `sshd` is intentionally removed from the final runtime image.

When running with a read-only root filesystem, the entrypoint may warn that `/etc/ssh` is not writable and host key generation is skipped. This is expected for this CLI-oriented image and does not affect outbound Git SSH client workflows.

---

## Git LFS

Git LFS is installed as a separate NiceOS RPM package and included in this application image.

The image provides system-wide Git LFS filter configuration in `/etc/gitconfig`:

```ini
[filter "lfs"]
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
    process = git-lfs filter-process
    required = true
```

Verify:

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r2 \
  /bin/bash -c 'git-lfs version && git lfs env'
```

---

## Arbitrary UID support

This image supports arbitrary UID execution through `nss_wrapper`.

Example:

```console
docker run --rm \
  --user 12345:0 \
  docker.io/niceos/git:2.54.0-niceos13-r2 \
  /bin/bash -c 'id && getent passwd "$(id -u)" && git --version'
```

Expected behavior:

- the arbitrary UID resolves through NSS;
- Git can run without a real `/etc/passwd` entry;
- `HOME=/` is used as the compatibility home.

---

## Read-only root filesystem

The image is compatible with read-only root filesystem execution for normal Git CLI workloads.

Example:

```console
docker run --rm \
  --user 12345:0 \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --read-only \
  --tmpfs /tmp:rw,exec,nosuid,nodev \
  --tmpfs /var/tmp:rw,exec,nosuid,nodev \
  --tmpfs /run:rw,nosuid,nodev \
  docker.io/niceos/git:2.54.0-niceos13-r2 \
  /bin/bash -c 'git --version && git ls-remote https://github.com/git/git.git HEAD >/dev/null && echo OK'
```

Recommended writable mounts:

```text
/tmp
/var/tmp
/run
/work or another project workspace
```

---

## Volumes

This image does not require a persistent volume for simple Git commands.

Common mounts:

| Host path | Container path | Purpose |
|---|---|---|
| `$PWD` | `/work` | project checkout/workspace |
| `$HOME/.ssh` | `/ssh:ro` | SSH credentials |
| `$HOME/.gitconfig` | `/.gitconfig:ro` | user Git config |
| custom storage | `/bitnami/git` | Bitnami-style persistent location |

Example:

```console
docker run --rm -it \
  -v "$PWD:/work" \
  -w /work \
  docker.io/niceos/git:2.54.0-niceos13-r2 \
  git status
```

---

## Compatibility with Bitnami-style workflows

This image is intended to preserve the runtime contract commonly expected by historical Bitnami Git containers:

| Contract area | Status |
|---|---|
| `/opt/bitnami` root | preserved |
| `/opt/bitnami/scripts` helper location | preserved |
| `/opt/bitnami/scripts/git/entrypoint.sh` | preserved |
| `/opt/bitnami/git/bin` command path | preserved |
| `/opt/bitnami/common/lib/libnss_wrapper.so` | preserved |
| `BITNAMI_*` environment variables | preserved |
| arbitrary UID | supported |
| `CMD ["/bin/bash"]` | preserved |
| `ENTRYPOINT` script behavior | preserved |
| Git over HTTPS | supported |
| Git over SSH client workflows | supported |
| Git LFS | supported |
| Debian/minideb/apt internals | replaced with NiceOS/RPM |
| Stacksmith prebuilt components | replaced with NiceOS RPMs |
| package manager in final runtime | removed |
| build tools in final runtime | removed |

### Migration example

Old style:

```console
docker run --rm bitnami/git:latest git --version
```

NiceOS style:

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r2 git --version
```

For production, prefer immutable tags instead of `latest`.

---

## Security posture

The final image is assembled from NiceOS.Container RPM packages and then cleaned.

Removed from runtime:

- `tdnf`
- `dnf`
- `yum`
- `systemctl`
- `sshd`
- `gcc`
- `make`
- `cmake`
- `ninja`
- package repository metadata
- RPM GPG key material copied only for build/install operations
- package manager caches
- documentation/man/info trees in the runtime root filesystem

Recommended runtime flags for restrictive environments:

```console
--cap-drop ALL
--security-opt no-new-privileges
--read-only
--tmpfs /tmp:rw,exec,nosuid,nodev
--tmpfs /var/tmp:rw,exec,nosuid,nodev
--tmpfs /run:rw,nosuid,nodev
```

For workflows that need SSH private keys, mount them read-only and use `GIT_SSH_COMMAND`.

---

## Building the image

Build locally:

```console
podman build --format docker --no-cache \
  --build-arg NICEOS_BASE_IMAGE=docker.io/niceosapps/niceos-container-base:13 \
  --build-arg NICEOS_VERSION=13 \
  --build-arg APP_VERSION=2.54.0 \
  --build-arg IMAGE_REVISION=1 \
  -t docker.io/niceos/git:2.54.0-niceos13-r2 \
  -t docker.io/niceos/git:2.54.0 \
  .
```

Optional compatibility tag for local testing with the historical internal namespace:

```console
podman tag docker.io/niceos/git:2.54.0-niceos13-r2 docker.io/niceosapps/git:2.54.0-niceos13-r2
```

---

## Testing

Run the local smoke suite:

```console
./tests/smoke.sh docker.io/niceos/git:2.54.0-niceos13-r2
```

Run the local compatibility suite:

```console
./tests/local-compat-suite.sh docker.io/niceos/git:2.54.0-niceos13-r2
```

Compare with the reference image, when available:

```console
./tests/compare-with-bitnami.sh \
  docker.io/bitnami/git:latest \
  docker.io/niceos/git:2.54.0-niceos13-r2
```

Run individual checks manually:

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r2 /bin/bash -c '
set -euo pipefail
test "$BITNAMI_APP_NAME" = "git"
test "$BITNAMI_ROOT_DIR" = "/opt/bitnami"
test "$BITNAMI_VOLUME_DIR" = "/bitnami"
test "$NSS_WRAPPER_LIB" = "/opt/bitnami/common/lib/libnss_wrapper.so"
test "$(command -v git)" = "/opt/bitnami/git/bin/git"
test "$(command -v git-lfs)" = "/opt/bitnami/git/bin/git-lfs"
git --version | grep "2.54.0"
git-lfs version | grep "3.7.1"
echo OK
'
```

---

## Repository layout

```text
.
├── compat
│   ├── bitnami-reference-commit.txt
│   └── contract.yaml
├── Dockerfile
├── rootfs
│   ├── .bash_profile
│   ├── etc
│   │   ├── gitconfig
│   │   └── profile.d
│   │       └── 00-bitnami-path.sh
│   └── opt
│       └── bitnami
│           └── scripts
│               └── git
│                   └── entrypoint.sh
└── tests
    ├── bitnami-contract-smoke.sh
    ├── compare-with-bitnami.sh
    ├── local-compat-suite.sh
    └── smoke.sh
```

`prebuildfs/` is intentionally not required for the production image build. The common Bitnami-compatible helper libraries are delivered by the NiceOS RPM package `niceos-bitnami-compat-scripts`.

`reports/` is treated as generated output from comparison/testing and should not be part of the normal Docker build context.

---

## Source, packaging, and provenance

NiceOS build model:

```text
NiceOS.Container RPM repository
  ├── git
  ├── git-lfs
  ├── nss_wrapper
  ├── niceos-bitnami-compat-scripts
  └── runtime dependencies

app-git repository
  ├── Dockerfile
  ├── rootfs application contract files
  ├── compatibility contract
  └── tests
```

The final image is assembled from RPM packages and application-specific compatibility files.

Recommended metadata labels include:

- `org.opencontainers.image.title`
- `org.opencontainers.image.description`
- `org.opencontainers.image.vendor`
- `org.opencontainers.image.version`
- `org.opencontainers.image.revision`
- `org.opencontainers.image.created`
- `org.opencontainers.image.source`
- `org.opencontainers.image.documentation`
- `org.opencontainers.image.licenses`
- `org.opencontainers.image.base.name`
- `ru.niceos.image.*`

---

## Licensing

The image contains software under multiple open source licenses.

Primary components:

- Git: GPL-2.0-only
- Git LFS: MIT
- nss_wrapper: BSD-3-Clause
- NiceOS compatibility scripts: Apache-2.0
- Application image metadata and NiceOS-specific integration files: Apache-2.0 unless stated otherwise

This repository may contain compatibility files derived from Apache-2.0 licensed historical Bitnami container scripts where explicitly noted. Bitnami, Broadcom, VMware, and related names are trademarks of their respective owners. Their mention is for compatibility and migration reference only.

---

## Support policy

This image is provided by NiceSOFT/NiceOS as part of the NiceOS Application Containers effort.

Recommended support workflow:

1. reproduce with the immutable image tag;
2. collect `git --version`, `git-lfs version`, and image digest;
3. run `tests/local-compat-suite.sh`;
4. open an issue in the NiceOS container repository;
5. include whether the issue is with HTTPS, SSH, LFS, arbitrary UID, read-only rootfs, or Helm/chart migration.

---

## Notable changes

### 2.54.0-niceos13-r2

- Initial NiceOS Git application image.
- Uses NiceOS.Container 13 base.
- Provides Git 2.54.0.
- Provides Git LFS 3.7.1.
- Preserves Bitnami-style `/opt/bitnami` layout.
- Preserves `/opt/bitnami/scripts/git/entrypoint.sh`.
- Uses `niceos-bitnami-compat-scripts` RPM for common helper libraries.
- Uses `nss_wrapper` for arbitrary UID support.
- Supports read-only root filesystem execution for Git CLI workflows.
- Removes package manager and build tools from the final runtime image.
- Replaces Debian/minideb/apt/Stacksmith internals with NiceOS RPM packages.

---

## Disclaimer

This is a NiceOS Application Container. It is not an official Bitnami container and is not affiliated with or endorsed by Bitnami, Broadcom, VMware, or the Git project. Compatibility references are used only to describe migration behavior and runtime contract expectations.

<!-- niceos:app-git-registries:begin -->
## Registries

Docker Hub:

```text
docker.io/niceos/git:2.54.0-niceos13-r2
docker.io/niceos/git:2.54.0
docker.io/niceos/git:latest
```

GitHub Container Registry:

```text
ghcr.io/niceos-containers/git:2.54.0-niceos13-r2
ghcr.io/niceos-containers/git:2.54.0
ghcr.io/niceos-containers/git:latest
```

Digests:

- Docker Hub immutable digest: `docker.io/niceos/git@sha256:612d39a6aa268a379e938bf7695d312b78ea7e522ead5779ce9ee5e0216fba0d`
- GHCR immutable digest: `ghcr.io/niceos-containers/git@sha256:612d39a6aa268a379e938bf7695d312b78ea7e522ead5779ce9ee5e0216fba0d`
<!-- niceos:app-git-registries:end -->
