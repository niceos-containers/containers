# syntax=docker/dockerfile:1.7
#
# NiceOS Application Container for Golang
#
# This image is a NiceOS.Container-based, Bitnami-layout-compatible
# migration target for workloads that currently expect bitnami/golang.
#
# Strict bitnami/golang compatibility:
#   - no Docker ENTRYPOINT
#   - no Docker USER
#   - default user is root
#   - CMD ["bash"]
#   - WORKDIR /go
#
# NiceOS differences:
#   - Go is installed from the NiceOS RPM package go1.26
#   - final image removes package-manager entry points and repository metadata
#   - RPM/glibc provenance is preserved through the NiceOS.Container build stream
#
# Build example:
#   podman build --format docker \
#     --build-arg APP_VERSION=1.26.4 \
#     --build-arg GO_RPM_NAME=go1.26 \
#     --build-arg NICEOS_STREAM=13 \
#     --build-arg IMAGE_REVISION=1 \
#     -t docker.io/niceos/golang:1.26.4-niceos13-r1 .

ARG NICEOS_STREAM=13
ARG NICEOS_BUILDER_IMAGE=docker.io/niceos/niceos-container-base:13
ARG TARGETARCH
ARG TARGETPLATFORM

FROM ${NICEOS_BUILDER_IMAGE} AS rootfs

ARG NICEOS_STREAM=13
ARG APP_VERSION=1.26.4
ARG IMAGE_REVISION=1
ARG GO_RPM_NAME=go1.26
ARG TARGETARCH
ARG TARGETPLATFORM
ARG INSTALLROOT=/niceos-rootfs

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# Packages intentionally kept in the final image:
#   - go1.26: NiceOS-packaged Go toolchain.
#   - git/curl/unzip/tar: common Go module and project workflows.
#   - gcc/make/binutils/glibc-devel/linux-api-headers/pkgconf: cgo-compatible builder image.
#
# Package manager entry points are removed from the final rootfs after install.
RUN set -eux; \
    mkdir -p "${INSTALLROOT}"; \
    tdnf -y --releasever "${NICEOS_STREAM}" --installroot "${INSTALLROOT}" install \
        niceos-release \
        niceos-repos \
        filesystem \
        bash \
        coreutils \
        findutils \
        sed \
        grep \
        gawk \
        tar \
        gzip \
        xz \
        zstd \
        ca-certificates \
        openssl \
        openssl-libs \
        curl \
        git \
        unzip \
        procps-ng \
        pkgconf \
        gcc \
        make \
        binutils \
        glibc \
        glibc-devel \
        linux-api-headers \
        libgcc \
        libstdc++ \
        ${GO_RPM_NAME}; \
    tdnf -y --installroot "${INSTALLROOT}" clean all || true; \
    rm -rf \
        "${INSTALLROOT}/var/cache/tdnf" \
        "${INSTALLROOT}/var/cache/dnf" \
        "${INSTALLROOT}/var/cache/yum" \
        "${INSTALLROOT}/var/lib/tdnf" \
        "${INSTALLROOT}/var/lib/dnf" \
        "${INSTALLROOT}/tmp"/* \
        "${INSTALLROOT}/var/tmp"/*

COPY rootfs/ ${INSTALLROOT}/

RUN set -eux; \
    mkdir -p \
        "${INSTALLROOT}/opt/bitnami" \
        "${INSTALLROOT}/bitnami/golang" \
        "${INSTALLROOT}/go/src" \
        "${INSTALLROOT}/go/bin" \
        "${INSTALLROOT}/go/pkg" \
        "${INSTALLROOT}/go/.cache" \
        "${INSTALLROOT}/tmp" \
        "${INSTALLROOT}/var/tmp" \
        "${INSTALLROOT}/run"; \
    \
    go_root_candidate=""; \
    for candidate in \
        "${INSTALLROOT}/opt/go-${APP_VERSION}" \
        "${INSTALLROOT}"/opt/go-* \
        "${INSTALLROOT}/usr/lib/go1.26" \
        "${INSTALLROOT}/usr/lib/golang" \
        "${INSTALLROOT}/usr/lib/go" \
        "${INSTALLROOT}/usr/lib64/go" \
        "${INSTALLROOT}/usr/local/go"; do \
        if [ -d "${candidate}" ] && [ -x "${candidate}/bin/go" ]; then \
            go_root_candidate="/${candidate#${INSTALLROOT}/}"; \
            break; \
        fi; \
    done; \
    if [ -z "${go_root_candidate}" ]; then \
        echo "Unable to locate Go GOROOT from RPM ${GO_RPM_NAME}" >&2; \
        echo "Expected NiceOS layout: /opt/go-${APP_VERSION}/bin/go" >&2; \
        find "${INSTALLROOT}/opt" "${INSTALLROOT}/usr" -maxdepth 5 \( -type f -o -type l \) -name go -print >&2 || true; \
        exit 1; \
    fi; \
    echo "Detected Go GOROOT: ${go_root_candidate}" >&2; \
    ln -sfn "${go_root_candidate}" "${INSTALLROOT}/opt/bitnami/go"; \
    if [ ! -e "${INSTALLROOT}/opt/go" ] && [ ! -L "${INSTALLROOT}/opt/go" ]; then \
        ln -sfn "${go_root_candidate}" "${INSTALLROOT}/opt/go"; \
    fi; \
    mkdir -p "${INSTALLROOT}/usr/bin"; \
    if [ ! -e "${INSTALLROOT}/usr/bin/go" ] && [ ! -L "${INSTALLROOT}/usr/bin/go" ]; then \
        ln -sfn /opt/bitnami/go/bin/go "${INSTALLROOT}/usr/bin/go"; \
    fi; \
    if [ ! -e "${INSTALLROOT}/usr/bin/gofmt" ] && [ ! -L "${INSTALLROOT}/usr/bin/gofmt" ]; then \
        ln -sfn /opt/bitnami/go/bin/gofmt "${INSTALLROOT}/usr/bin/gofmt"; \
    fi; \
    test -x "${INSTALLROOT}${go_root_candidate}/bin/go"; \
    test -x "${INSTALLROOT}${go_root_candidate}/bin/gofmt"; \
    \
    # Temporary compatibility workaround until NiceOS gcc/libgcc packaging
    # provides libgcc-devel with this linker-name symlink.
    libgcc_s_runtime="$(find "${INSTALLROOT}/usr" -name 'libgcc_s.so.1' -type f -print -quit || true)"; \
    if [ -n "${libgcc_s_runtime}" ]; then \
        libgcc_s_dir="$(dirname "${libgcc_s_runtime}")"; \
        if [ ! -e "${libgcc_s_dir}/libgcc_s.so" ]; then \
            ln -sfn libgcc_s.so.1 "${libgcc_s_dir}/libgcc_s.so"; \
        fi; \
    fi; \
    if ! find "${INSTALLROOT}/usr" -name 'libgcc_s.so' \( -type f -o -type l \) -print -quit | grep -q .; then \
        echo "Unable to locate or create libgcc_s.so linker name for cgo" >&2; \
        find "${INSTALLROOT}/usr" -name 'libgcc_s*' -print >&2 || true; \
        exit 1; \
    fi; \
    \
    chmod -R 0777 \
        "${INSTALLROOT}/go" \
        "${INSTALLROOT}/tmp" \
        "${INSTALLROOT}/var/tmp"; \
    chmod -R g+rwX \
        "${INSTALLROOT}/bitnami" \
        "${INSTALLROOT}/run"; \
    \
    rm -f \
        "${INSTALLROOT}/usr/bin/tdnf" \
        "${INSTALLROOT}/usr/bin/dnf" \
        "${INSTALLROOT}/usr/bin/yum" \
        "${INSTALLROOT}/usr/bin/rpm" \
        "${INSTALLROOT}/usr/bin/rpm2cpio" \
        "${INSTALLROOT}/bin/rpm" \
        "${INSTALLROOT}/sbin/tdnf" \
        "${INSTALLROOT}/sbin/dnf" \
        "${INSTALLROOT}/sbin/yum" || true; \
    rm -rf \
        "${INSTALLROOT}/etc/yum.repos.d" \
        "${INSTALLROOT}/etc/dnf" \
        "${INSTALLROOT}/etc/tdnf" \
        "${INSTALLROOT}/var/cache/tdnf" \
        "${INSTALLROOT}/var/cache/dnf" \
        "${INSTALLROOT}/var/cache/yum" \
        "${INSTALLROOT}/usr/share/doc" \
        "${INSTALLROOT}/usr/share/man" \
        "${INSTALLROOT}/usr/share/info"; \
    find "${INSTALLROOT}" -perm /6000 -type f -exec chmod a-s {} + || true; \
    \
    cat > "${INSTALLROOT}/.niceos-image-release" <<EOF
NAME=golang
APP_VERSION=${APP_VERSION}
GO_RPM_NAME=${GO_RPM_NAME}
NICEOS_STREAM=${NICEOS_STREAM}
IMAGE_REVISION=${IMAGE_REVISION}
IMAGE_TAG=${APP_VERSION}-niceos${NICEOS_STREAM}-r${IMAGE_REVISION}
BITNAMI_LAYOUT_COMPATIBLE=yes
STRICT_BITNAMI_GOLANG_DOCKER_CONFIG=yes
EOF

FROM scratch

ARG NICEOS_STREAM=13
ARG APP_VERSION=1.26.4
ARG IMAGE_REVISION=1
ARG GO_RPM_NAME=go1.26
ARG TARGETARCH
ARG TARGETPLATFORM

COPY --from=rootfs /niceos-rootfs /

LABEL org.opencontainers.image.title="golang" \
      org.opencontainers.image.description="NiceOS.Container Golang image with strict Bitnami-compatible Docker command layout" \
      org.opencontainers.image.vendor="NiceSOFT" \
      org.opencontainers.image.authors="NiceSOFT LLC / ООО \"НАЙС СОФТ ГРУПП\" <niceos@ncsgp.ru>" \
      org.opencontainers.image.source="https://github.com/niceos-containers/containers/tree/main/apps/golang" \
      org.opencontainers.image.documentation="https://github.com/niceos-containers/containers/tree/main/apps/golang/README.md" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="r${IMAGE_REVISION}" \
      org.opencontainers.image.base.name="NiceOS.Container ${NICEOS_STREAM}" \
      ru.niceos.container.stream="${NICEOS_STREAM}" \
      ru.niceos.container.app="golang" \
      ru.niceos.container.rpm="${GO_RPM_NAME}" \
      ru.niceos.container.bitnami-compatible="true" \
      ru.niceos.container.bitnami-strict-docker-config="true" \
      ru.niceos.container.layout.opt-bitnami="true" \
      ru.niceos.container.default-user="root"

ENV APP_VERSION="${APP_VERSION}" \
    BITNAMI_APP_NAME="golang" \
    BITNAMI_IMAGE_VERSION="${APP_VERSION}-niceos${NICEOS_STREAM}-r${IMAGE_REVISION}" \
    GOCACHE="/go/.cache" \
    GOMODCACHE="/go/pkg/mod" \
    GOPATH="/go" \
    GOROOT="/opt/bitnami/go" \
    HOME="/go" \
    IMAGE_REVISION="${IMAGE_REVISION}" \
    NICEOS_CONTAINER_STREAM="${NICEOS_STREAM}" \
    NICEOS_GO_RPM_NAME="${GO_RPM_NAME}" \
    OS_ARCH="${TARGETARCH}" \
    OS_FLAVOUR="niceos-container-${NICEOS_STREAM}" \
    OS_NAME="linux" \
    PATH="/go/bin:/opt/bitnami/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

WORKDIR /go
CMD ["bash"]
