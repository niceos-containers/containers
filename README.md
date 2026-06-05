# NiceOS Application Containers

**NiceOS Application Containers** are free, RPM-based, glibc-based application container images built on the **NiceOS.Container** stream.

The project exists to provide familiar, enterprise-friendly application images and **Bitnami-compatible migration targets** while replacing Debian/minideb/apt/Stacksmith-style internals with NiceOS RPM packages, reproducible build pipelines, transparent metadata, and a controlled operating-system base.

This repository is the public monorepo for NiceOS application images.

```text
docker.io/niceos/git:latest
docker.io/niceos/git:2.54.0
docker.io/niceos/git:2.54.0-niceos13-r1
```

For production use, prefer immutable tags such as:

```text
docker.io/niceos/git:2.54.0-niceos13-r1
```

The `latest` tag is a convenience channel and may move.

---

## Table of contents

- [What is NiceOS?](#what-is-niceos)
- [What is NiceOS.Container?](#what-is-niceoscontainer)
- [What are NiceOS Application Containers?](#what-are-niceos-application-containers)
- [Why this project exists](#why-this-project-exists)
- [Why Bitnami-compatible images?](#why-bitnami-compatible-images)
- [What compatibility means](#what-compatibility-means)
- [What compatibility does not mean](#what-compatibility-does-not-mean)
- [Published images](#published-images)
- [Repository layout](#repository-layout)
- [Release and update model](#release-and-update-model)
- [Tagging policy](#tagging-policy)
- [How images are built](#how-images-are-built)
- [How to verify an image](#how-to-verify-an-image)
- [Security posture](#security-posture)
- [Why RPM?](#why-rpm)
- [Why glibc?](#why-glibc)
- [Why not Alpine?](#why-not-alpine)
- [Why not Debian-based images?](#why-not-debian-based-images)
- [Why not just use upstream images?](#why-not-just-use-upstream-images)
- [NiceOS compatibility contract](#niceos-compatibility-contract)
- [Source of truth and public mirror model](#source-of-truth-and-public-mirror-model)
- [How to build locally](#how-to-build-locally)
- [How to test locally](#how-to-test-locally)
- [How releases are automated](#how-releases-are-automated)
- [Roadmap](#roadmap)
- [FAQ](#faq)
- [Licensing and trademarks](#licensing-and-trademarks)
- [Disclaimer](#disclaimer)

---

## What is NiceOS?

**NiceOS** is an operating-system project built around the idea that modern infrastructure should be familiar, auditable, reproducible, and practical.

The core design goals are:

- use a familiar Linux userland;
- use `glibc` for broad application compatibility;
- use RPM packaging for clear package ownership and lifecycle control;
- keep build and runtime artifacts traceable;
- keep security updates and rebuilds under project control;
- avoid hiding important runtime behavior behind opaque base images;
- provide enterprise-friendly images without making the images proprietary;
- keep open source images open source.

NiceOS is not designed as a toy minimal distribution. It is designed as a controlled platform for real server, container, Kubernetes, CI/CD, and application workloads.

NiceOS Application Containers are one part of that larger direction.

---

## What is NiceOS.Container?

**NiceOS.Container** is a container-focused NiceOS stream.

It is separate from a full server/workstation operating system. It is intentionally lighter and focused on container image composition.

NiceOS.Container is designed for:

- application container base images;
- compatibility layers;
- Bitnami-style migration targets;
- Kubernetes workloads;
- CI/CD tools;
- reproducible image assembly;
- package-managed container root filesystems;
- non-root and arbitrary UID operation;
- read-only root filesystem execution.

NiceOS.Container is not a full interactive server OS. It does not need systemd inside ordinary application images. It does not need a package manager in the final runtime image. It does not need compilers in production containers.

The build pipeline may use RPM and `tdnf` to assemble the filesystem, but the final runtime image removes package-manager commands and build-time tools where possible.

---

## What are NiceOS Application Containers?

**NiceOS Application Containers** are application images built on top of NiceOS.Container.

An application image is not just a package installed in a base image. A production application container needs a runtime contract:

- paths;
- entrypoint behavior;
- environment variables;
- volume locations;
- user and group behavior;
- health-check expectations;
- read-only root filesystem behavior;
- non-root behavior;
- configuration conventions;
- upgrade and migration expectations.

NiceOS Application Containers define and test this contract explicitly.

The first published image in this monorepo is:

```text
docker.io/niceos/git
```

It provides:

- Git;
- Git LFS;
- OpenSSH client tools;
- HTTPS Git support;
- arbitrary UID support through `nss_wrapper`;
- Bitnami-style `/opt/bitnami` layout;
- read-only root filesystem support for normal CLI workflows;
- no package manager in the final runtime image;
- no build tools in the final runtime image.

---

## Why this project exists

Application containers became a critical part of modern infrastructure, but the ecosystem has a practical problem: many widely used images depend on implicit runtime contracts that are not obvious from a package list.

A container is not only:

```text
base image + package install
```

It is also:

```text
runtime layout + entrypoint + env API + user model + filesystem model + chart compatibility
```

Many organizations have existing automation that expects Bitnami-style behavior:

- `/opt/bitnami`;
- `/bitnami/<app>`;
- `BITNAMI_*` environment variables;
- non-root users;
- arbitrary UID behavior;
- Helm chart values;
- app-specific entrypoint scripts;
- compatibility helper libraries.

When those assumptions change, migration becomes expensive.

NiceOS Application Containers were created to provide a controlled migration path:

```text
Historical Bitnami-style runtime contract
        ↓
NiceOS/RPM/glibc based implementation
        ↓
Free, open, reproducible application images
```

This is not about cloning another vendor. It is about preserving operational compatibility where users already depend on it, while rebuilding the image internals on a NiceOS foundation.

---

## Why Bitnami-compatible images?

Bitnami images and charts became a de facto operational interface for many teams.

For many users, the important part was not the internal Debian base. The important part was the behavior:

- how the image starts;
- which variables are supported;
- where files are stored;
- which user the application runs as;
- what Helm values exist;
- where scripts live;
- which ports and probes are expected;
- how configuration is mounted;
- how upgrades are performed.

NiceOS compatibility images preserve those practical contracts where possible.

The goal is:

```text
Make migration boring.
```

A team should be able to take an existing Bitnami-style workflow, replace the image reference, run tests, and migrate with minimal operational surprise.

---

## What compatibility means

For this project, **compatibility** means preserving the runtime behavior that users and charts depend on.

Examples:

```text
/opt/bitnami
/opt/bitnami/scripts
/opt/bitnami/scripts/<app>/entrypoint.sh
/opt/bitnami/<app>/bin
/opt/bitnami/common/bin
/opt/bitnami/common/lib/libnss_wrapper.so
/bitnami/<app>
BITNAMI_APP_NAME
BITNAMI_ROOT_DIR
BITNAMI_VOLUME_DIR
NSS_WRAPPER_LIB
arbitrary UID support
non-root-friendly filesystem permissions
read-only root filesystem behavior where practical
```

For Helm-based applications, compatibility also means preserving chart-facing behavior:

- environment variable names;
- `*_FILE` secret conventions where relevant;
- volume paths;
- ports;
- probes;
- container security context expectations;
- UID/GID behavior;
- default command and entrypoint assumptions.

Each app should carry a compatibility contract under:

```text
apps/<name>/compat/contract.yaml
```

---

## What compatibility does not mean

Compatibility does **not** mean that NiceOS is an official Bitnami replacement.

Compatibility does **not** mean that NiceOS copies Debian/minideb internals.

Compatibility does **not** mean that Stacksmith build logic is used.

Compatibility does **not** mean that the project is endorsed by Bitnami, Broadcom, VMware, or any upstream application vendor.

Compatibility means:

```text
The runtime contract is intentionally similar where users need it,
but the implementation is NiceOS-based.
```

NiceOS Application Containers are independent images built by NiceSOFT/NiceOS.

---

## Published images

| App | Image | Status | Runtime | Compatibility |
|---|---|---:|---|---|
| Git | `docker.io/niceos/git` | Published | Git 2.54.0 + Git LFS 3.7.1 | Bitnami-compatible migration target |

Current Git image tags:

```text
docker.io/niceos/git:2.54.0-niceos13-r1
docker.io/niceos/git:2.54.0
docker.io/niceos/git:latest
```

Quick start:

```console
docker run --rm docker.io/niceos/git:latest git --version
```

Production:

```console
docker run --rm docker.io/niceos/git:2.54.0-niceos13-r1 git --version
```

---

## Repository layout

This repository is a public monorepo.

```text
.
├── apps/
│   └── git/
│       ├── Dockerfile
│       ├── README.md
│       ├── compat/
│       │   └── contract.yaml
│       ├── docs/
│       │   └── releases/
│       ├── rootfs/
│       ├── tests/
│       └── .niceos-source.yaml
└── catalog/
    └── apps.yaml
```

### `apps/<name>/`

Application-specific container source.

Each app directory contains:

- Dockerfile or Containerfile;
- app README;
- app compatibility contract;
- app root filesystem overlay;
- app smoke tests;
- release documentation;
- source metadata.

### `catalog/apps.yaml`

Public index of published application images.

It records:

- image name;
- tags;
- digest;
- app version;
- NiceOS.Container version;
- compatibility mode;
- source-of-truth repository;
- source commit.

### `.niceos-source.yaml`

Each mirrored app directory contains a provenance file:

```text
apps/<name>/.niceos-source.yaml
```

It explains where the app really comes from, which internal source commit was mirrored, and which image tags were published.

---

## Release and update model

NiceOS Application Containers use a controlled release model.

There are three moving parts:

1. **NiceOS.Container base**
2. **Application RPM packages**
3. **Application container image revision**

Example:

```text
docker.io/niceos/git:2.54.0-niceos13-r1
```

Meaning:

```text
2.54.0     upstream application version
niceos13   NiceOS.Container stream
r1         image revision
```

### Application updates

When a new upstream Git version is packaged in NiceOS.Container:

```text
git 2.54.0 → git 2.55.0
```

the app image can be released as:

```text
docker.io/niceos/git:2.55.0-niceos13-r1
```

### Image-only rebuilds

If the Git version stays the same but the image contract, base packages, scripts, or security metadata changes, the image revision changes:

```text
2.54.0-niceos13-r1 → 2.54.0-niceos13-r2
```

### Base stream updates

When the NiceOS.Container stream changes:

```text
niceos13 → niceos14
```

images move to new tags:

```text
2.54.0-niceos14-r1
```

### Security rebuilds

If a dependency receives a security update but the app version stays the same, the image revision should be bumped:

```text
2.54.0-niceos13-r1 → 2.54.0-niceos13-r2
```

The release manifest should explain why.

---

## Tagging policy

Recommended tags:

```text
<app-version>-niceos<stream>-r<revision>
<app-version>
latest
```

Example:

```text
2.54.0-niceos13-r1
2.54.0
latest
```

### Immutable production tag

```text
2.54.0-niceos13-r1
```

This is the safest production tag. It should not move after publication.

### Version tag

```text
2.54.0
```

This tag points to the recommended image for that upstream application version. It may move from `r1` to `r2` if the same app version is rebuilt.

### Latest tag

```text
latest
```

This is a convenience tag. It may move to a newer application version.

Production users should avoid relying on `latest`.

### Digest pinning

For maximum reproducibility, use a digest:

```text
docker.io/niceos/git@sha256:<digest>
```

---

## How images are built

The build model is intentionally simple and auditable.

For the Git image, the Dockerfile performs roughly this process:

1. Start from a NiceOS.Container base image.
2. Create an install root.
3. Install runtime RPM packages into that root.
4. Copy application-specific rootfs overlay.
5. Create compatibility symlinks under `/opt/bitnami`.
6. Configure compatibility files.
7. Remove package manager metadata.
8. Remove package manager commands from final runtime.
9. Remove build tools from final runtime.
10. Copy the resulting root filesystem into a scratch final image.
11. Set OCI labels, environment variables, entrypoint, and command.

The final image is not a build container. It is a runtime image.

The package manager is used during image assembly, not as part of the runtime user experience.

---

## How to verify an image

Use the immutable tag:

```bash
IMAGE=docker.io/niceos/git:2.54.0-niceos13-r1
```

### Pull

```bash
podman pull "$IMAGE"
```

### Check versions

```bash
podman run --rm "$IMAGE" git --version
podman run --rm "$IMAGE" git-lfs version
```

Expected:

```text
git version 2.54.0
git-lfs/3.7.1
```

### Check command paths

```bash
podman run --rm "$IMAGE" /bin/bash -c '
set -euo pipefail
command -v git
command -v git-lfs
'
```

Expected:

```text
/opt/bitnami/git/bin/git
/opt/bitnami/git/bin/git-lfs
```

### Check Bitnami-style environment

```bash
podman run --rm "$IMAGE" /bin/bash -c '
set -euo pipefail

test "$BITNAMI_APP_NAME" = "git"
test "$BITNAMI_ROOT_DIR" = "/opt/bitnami"
test "$BITNAMI_VOLUME_DIR" = "/bitnami"
test "$NSS_WRAPPER_LIB" = "/opt/bitnami/common/lib/libnss_wrapper.so"

test -x /opt/bitnami/scripts/git/entrypoint.sh
test -e /opt/bitnami/common/lib/libnss_wrapper.so
test -d /bitnami/git

echo OK
'
```

### Check Git LFS configuration

```bash
podman run --rm "$IMAGE" /bin/bash -c '
set -euo pipefail

git config --system --get filter.lfs.clean
git config --system --get filter.lfs.smudge
git config --system --get filter.lfs.process
git config --system --get filter.lfs.required

git lfs env >/dev/null

echo OK
'
```

Expected:

```text
git-lfs clean -- %f
git-lfs smudge -- %f
git-lfs filter-process
true
OK
```

### Check arbitrary UID

```bash
podman run --rm \
  --user 12345:0 \
  "$IMAGE" \
  /bin/bash -c '
set -euo pipefail
id
getent passwd "$(id -u)"
git --version
echo OK
'
```

This verifies that arbitrary UID support works through `nss_wrapper`.

### Check read-only root filesystem

```bash
podman run --rm \
  --user 12345:0 \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --read-only \
  --tmpfs /tmp:rw,exec,nosuid,nodev \
  --tmpfs /var/tmp:rw,exec,nosuid,nodev \
  --tmpfs /run:rw,nosuid,nodev \
  "$IMAGE" \
  /bin/bash -c '
set -euo pipefail
id
getent passwd "$(id -u)"
git --version
git-lfs version
ssh-keygen -q -t ed25519 -N "" -f /tmp/key
echo OK
'
```

### Check HTTPS Git access

```bash
podman run --rm "$IMAGE" \
  git ls-remote https://github.com/git/git.git HEAD
```

### Check that forbidden tools are absent

```bash
podman run --rm "$IMAGE" /bin/bash -c '
set -euo pipefail

for x in tdnf dnf yum systemctl sshd gcc make cmake ninja; do
  if command -v "$x" >/dev/null 2>&1; then
    echo "FORBIDDEN command: $x -> $(command -v "$x")"
    exit 1
  fi
done

echo OK
'
```

---

## Security posture

NiceOS Application Containers are designed to reduce unnecessary runtime surface.

The final runtime image should not contain:

- package manager commands;
- package repository metadata;
- compilers;
- build systems;
- systemd;
- SSH server daemon unless the app explicitly requires it;
- temporary build artifacts;
- cached RPM packages;
- vendored build archives;
- generated reports.

For `docker.io/niceos/git`, the final image intentionally removes:

```text
tdnf
dnf
yum
systemctl
sshd
gcc
make
cmake
ninja
```

The Git image keeps:

```text
bash
coreutils
findutils
grep
sed
gawk
curl
ca-certificates
git
git-lfs
openssh-clients
nss_wrapper
procps-ng
gzip
tar
less
```

These are kept because they support practical Git, Git LFS, SSH, HTTPS, debugging, and Bitnami-style runtime behavior.

---

## Why RPM?

NiceOS uses RPM because RPM gives clear package identity, ownership, metadata, dependency control, reproducible build discipline, and mature lifecycle tooling.

For container images, this matters because every file should have an origin.

A package-managed root filesystem makes it possible to answer:

- which package installed this file;
- which version installed it;
- which release fixed a vulnerability;
- which changelog entry explains the change;
- which source package produced the binary;
- which repository provided it.

This is better than treating a container as an unstructured pile of copied files.

RPM is also familiar in enterprise Linux environments. Many administrators, scanners, and compliance workflows already understand RPM metadata.

NiceOS Application Containers use RPM during image assembly and remove package management tools from final runtime images where possible.

---

## Why glibc?

NiceOS uses `glibc` because many enterprise workloads assume glibc behavior.

The goal is compatibility with familiar Linux applications, not winning the smallest possible image-size contest at the cost of runtime surprises.

A glibc-based container can be more predictable for:

- upstream binaries;
- vendor tools;
- language runtimes;
- debugging utilities;
- enterprise agents;
- security scanners;
- compatibility with existing Linux expectations.

NiceOS Application Containers prefer familiar behavior over extreme minimalism.

---

## Why not Alpine?

Alpine is excellent for many workloads, but NiceOS Application Containers are intentionally not Alpine-based.

Reasons:

- Alpine uses musl libc, while many enterprise applications assume glibc.
- Some upstream binaries are built and tested primarily against glibc.
- Some debugging, profiling, and operational behavior differs.
- Some users prefer RPM metadata and enterprise Linux conventions.
- Migration from Bitnami-style glibc/Debian behavior to musl may introduce surprises.

NiceOS is not trying to be the smallest possible base. It is trying to be familiar, reproducible, and compatible.

---

## Why not Debian-based images?

Debian-based images are common and useful, but NiceOS wants a different control model.

NiceOS Application Containers replace Debian/minideb/apt internals with:

- NiceOS.Container base images;
- NiceOS RPM packages;
- NiceOS release metadata;
- NiceOS compatibility layers;
- NiceOS security and rebuild policy;
- NiceOS release manifests.

The point is not that Debian is bad. The point is that NiceOS wants full control over the base, packages, compatibility contracts, and rebuild lifecycle.

---

## Why not just use upstream images?

For many users, upstream images are enough.

NiceOS Application Containers are useful when you need:

- predictable RPM-based provenance;
- glibc runtime behavior;
- Bitnami-style migration compatibility;
- non-root and arbitrary UID support;
- read-only root filesystem support;
- image-level release manifests;
- controlled image tags;
- a base OS maintained as part of a broader NiceOS ecosystem;
- a public free alternative with explicit compatibility contracts.

The goal is not to replace every upstream image. The goal is to provide a controlled migration and operations layer for users who need it.

---

## NiceOS compatibility contract

Each app should define a compatibility contract.

For Git, the contract includes:

```text
/opt/bitnami
/opt/bitnami/git/bin
/opt/bitnami/common/bin
/opt/bitnami/common/lib/libnss_wrapper.so
/opt/bitnami/scripts/git/entrypoint.sh
/bitnami/git
BITNAMI_APP_NAME
BITNAMI_ROOT_DIR
BITNAMI_VOLUME_DIR
NSS_WRAPPER_LIB
Git LFS filter configuration
arbitrary UID support
read-only rootfs support
```

The contract is documented in:

```text
apps/git/compat/contract.yaml
```

Future application images should also include a contract file.

---

## Source of truth and public mirror model

NiceOS uses a split source model.

Internal source of truth:

```text
https://specs.niceos.ru/niceos-containers/app-git
```

Public GitHub monorepo mirror:

```text
https://github.com/niceos-containers/containers/tree/main/apps/git
```

Docker Hub image:

```text
https://hub.docker.com/r/niceos/git
```

The internal per-app repository is where production work happens.

The GitHub monorepo is the public distribution and discovery layer.

This model gives:

- clean per-app internal development;
- clean public monorepo browsing;
- Bitnami-like discoverability;
- app-level source provenance;
- ability to mirror selected apps publicly;
- ability to keep internal automation separate from public layout.

Each mirrored app carries:

```text
apps/<name>/.niceos-source.yaml
```

This file records the internal source URL, commit, tag, public path, image tags, and compatibility metadata.

---

## How to build locally

From the app directory:

```bash
cd apps/git
```

Build:

```bash
podman build --format docker --no-cache \
  --build-arg NICEOS_BASE_IMAGE=docker.io/niceosapps/niceos-container-base:13 \
  --build-arg NICEOS_VERSION=13 \
  --build-arg APP_VERSION=2.54.0 \
  --build-arg IMAGE_REVISION=1 \
  --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --build-arg VCS_REF="$(git rev-parse --short=12 HEAD 2>/dev/null || echo unknown)" \
  -t docker.io/niceos/git:2.54.0-niceos13-r1 \
  -t docker.io/niceos/git:2.54.0 \
  .
```

Run:

```bash
podman run --rm docker.io/niceos/git:2.54.0-niceos13-r1 git --version
```

---

## How to test locally

Run app smoke tests where available:

```bash
cd apps/git

./tests/smoke.sh docker.io/niceos/git:2.54.0-niceos13-r1
./tests/local-compat-suite.sh docker.io/niceos/git:2.54.0-niceos13-r1
```

Manual minimum test:

```bash
IMAGE=docker.io/niceos/git:2.54.0-niceos13-r1

podman run --rm "$IMAGE" git --version
podman run --rm "$IMAGE" git-lfs version
podman run --rm "$IMAGE" git lfs env
```

Read-only root filesystem test:

```bash
podman run --rm \
  --user 12345:0 \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --read-only \
  --tmpfs /tmp:rw,exec,nosuid,nodev \
  --tmpfs /var/tmp:rw,exec,nosuid,nodev \
  --tmpfs /run:rw,nosuid,nodev \
  "$IMAGE" \
  /bin/bash -c 'id && getent passwd "$(id -u)" && git --version && echo OK'
```

---

## How releases are automated

NiceOS uses release automation for app images.

For `app-git`, the release script performs the following work:

1. Update app metadata and version references.
2. Generate release notes.
3. Generate release manifest.
4. Commit source-of-truth repository.
5. Tag source-of-truth repository.
6. Build image with Podman.
7. Run compatibility tests.
8. Push Docker Hub tags.
9. Obtain registry digest.
10. Sync the app into this public monorepo.
11. Update `.niceos-source.yaml`.
12. Update `catalog/apps.yaml`.
13. Commit this monorepo.
14. Tag this monorepo.

Example:

```bash
niceos_app_git_release.py 2.55.0 --revision 1 -y
```

Expected output tags:

```text
docker.io/niceos/git:2.55.0-niceos13-r1
docker.io/niceos/git:2.55.0
docker.io/niceos/git:latest
```

---

## Roadmap

Planned direction:

- publish more application images;
- add nginx as the next application image;
- add Redis;
- add PostgreSQL;
- add MariaDB;
- add RabbitMQ;
- add per-app compatibility contracts;
- add per-app release manifests;
- add SBOM generation;
- add vulnerability scanning reports;
- add signed image provenance;
- add Helm chart migration overlays;
- add compatibility test matrix;
- add multi-architecture builds;
- add registry mirror under NiceOS infrastructure.

The project should grow app by app, with each image having:

- clear purpose;
- clear compatibility contract;
- clear Docker Hub tags;
- clear release manifest;
- clear tests;
- clear source provenance.

---

## FAQ

### Is this an official Bitnami project?

No.

NiceOS Application Containers are independent NiceOS images.

Bitnami compatibility references are used to describe runtime migration behavior only.

### Is this a drop-in replacement?

The goal is migration compatibility, not blind replacement.

Each app should be tested with its chart, workload, volume layout, security context, and upgrade path.

### Why preserve `/opt/bitnami`?

Because existing charts and scripts may depend on it.

Changing paths is easy for a clean-sheet image but expensive for migration.

### Why keep `BITNAMI_*` variables?

Because they are part of the practical runtime contract.

### Why keep arbitrary UID support?

Because Kubernetes platforms often run containers with arbitrary UIDs, especially in restricted environments.

### Why keep read-only root filesystem support?

Because it is a useful hardening model and is expected in many production Kubernetes environments.

### Why remove the package manager?

Because final runtime images should not behave like mutable servers.

Package installation belongs in the build pipeline, not in production containers.

### Why include Bash?

Because many compatibility entrypoints and operational workflows assume Bash behavior.

The goal is not extreme minimalism; the goal is reliable migration and predictable operation.

### Why include Git LFS in the Git image?

Because many real Git workflows require it, and Bitnami-style Git images often need LFS compatibility.

### Why include OpenSSH clients?

Because Git over SSH is a core Git workflow.

The image includes SSH clients, not an SSH server.

### Why does read-only rootfs sometimes warn about `/etc/ssh`?

The entrypoint may skip SSH host key generation when `/etc/ssh` is not writable.

For this CLI-oriented Git image, that is acceptable. The image is not an SSH server image, and outbound Git SSH client workflows are unaffected.

### Can I use `latest`?

Yes, for quick starts and testing.

For production, use an immutable tag or digest.

### Can I use this in Kubernetes?

Yes, but use explicit tags, set an appropriate `securityContext`, and mount writable work directories as needed.

### Will images remain free?

The project direction is free and open application images.

NiceOS Application Containers are intended as community-usable infrastructure, not as proprietary locked images.

---

## Contributing

Recommended contribution flow:

1. Open an issue describing the app or compatibility problem.
2. Include the exact image tag.
3. Include the command or Helm values used.
4. Include whether the issue affects:
   - entrypoint;
   - environment variables;
   - UID/GID;
   - volume layout;
   - read-only rootfs;
   - Git/SSH/HTTPS;
   - Git LFS;
   - chart compatibility.
5. Provide logs from the immutable tag.

For new apps, each app should include:

```text
apps/<name>/README.md
apps/<name>/Dockerfile
apps/<name>/compat/contract.yaml
apps/<name>/rootfs/
apps/<name>/tests/
apps/<name>/.niceos-source.yaml
```

---

## Licensing and trademarks

Repository integration files are licensed under Apache-2.0 unless stated otherwise.

Container images include software under their respective upstream licenses.

Examples:

- Git: GPL-2.0-only
- Git LFS: MIT
- nss_wrapper: BSD-3-Clause
- NiceOS compatibility scripts: Apache-2.0

Bitnami, Broadcom, VMware, Git, Linux, Docker, Kubernetes, and other names may be trademarks of their respective owners.

Mentioning a project or trademark does not imply endorsement.

---

## Disclaimer

NiceOS Application Containers are provided as independent NiceOS images.

They are not official Bitnami images.

They are not endorsed by Bitnami, Broadcom, VMware, Docker, GitHub, the Git project, or any other third-party vendor unless explicitly stated.

Compatibility is a technical migration goal and should be validated in your own environment before production use.
