# syntax=docker/dockerfile:1.7
# SPDX-License-Identifier: Apache-2.0

ARG NICEOS_VERSION=13
ARG NICEOS_BASE_IMAGE=docker.io/niceos/niceos-container-base:13
ARG APP_VERSION=1.5.1
ARG IMAGE_REVISION=1
ARG BUILD_DATE=1970-01-01T00:00:00Z
ARG VCS_REF=unknown
ARG TARGETARCH=amd64

FROM ${NICEOS_BASE_IMAGE} AS rootfs

ARG NICEOS_VERSION
ARG APP_VERSION
ARG IMAGE_REVISION
ARG BUILD_DATE
ARG VCS_REF
ARG TARGETARCH
ARG INSTALLROOT=/niceos-rootfs
ARG NICEOS_EXPORTER_PACKAGE=nginx-prometheus-exporter

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN set -eux; \
    mkdir -p "${INSTALLROOT}"; \
    tdnf -y \
      --installroot="${INSTALLROOT}" \
      --releasever="${NICEOS_VERSION}" \
      --setopt=install_weak_deps=0 \
      --setopt=tsflags=nodocs \
      install \
        niceos-release \
        niceos-repos \
        filesystem \
        bash \
        coreutils \
        findutils \
        grep \
        sed \
        gawk \
        ca-certificates \
        procps-ng \
        "${NICEOS_EXPORTER_PACKAGE}"; \
    forbidden="$(rpm --root "${INSTALLROOT}" -qa | grep -E '^(gcc|gcc-c\+\+|glibc-devel|binutils|make|cmake|ninja|meson|flex|m4|perl|niceos-perl-macros|mpc-devel|go|golang)-' || true)"; \
    if [ -n "${forbidden}" ]; then \
      echo "Forbidden build packages pulled into runtime installroot:" >&2; \
      echo "${forbidden}" >&2; \
      exit 1; \
    fi; \
    tdnf -y --installroot="${INSTALLROOT}" clean all || true; \
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
    install -d -m 0775 \
      "${INSTALLROOT}/opt/bitnami" \
      "${INSTALLROOT}/opt/bitnami/nginx-exporter" \
      "${INSTALLROOT}/opt/bitnami/nginx-exporter/bin" \
      "${INSTALLROOT}/opt/bitnami/scripts" \
      "${INSTALLROOT}/opt/bitnami/scripts/nginx-exporter" \
      "${INSTALLROOT}/tmp" \
      "${INSTALLROOT}/var/tmp"; \
    \
    if [ -x "${INSTALLROOT}/usr/bin/nginx-prometheus-exporter" ]; then \
      ln -sfn /usr/bin/nginx-prometheus-exporter "${INSTALLROOT}/opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter"; \
    elif [ -x "${INSTALLROOT}/usr/sbin/nginx-prometheus-exporter" ]; then \
      ln -sfn /usr/sbin/nginx-prometheus-exporter "${INSTALLROOT}/opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter"; \
    elif [ -x "${INSTALLROOT}/bin/nginx-prometheus-exporter" ]; then \
      ln -sfn /bin/nginx-prometheus-exporter "${INSTALLROOT}/opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter"; \
    else \
      echo "Unable to locate nginx-prometheus-exporter from RPM package ${NICEOS_EXPORTER_PACKAGE}" >&2; \
      find "${INSTALLROOT}" -maxdepth 5 -type f -name '*nginx*exporter*' -ls >&2 || true; \
      exit 1; \
    fi; \
    ln -sfn /opt/bitnami/nginx-exporter/bin/nginx-prometheus-exporter "${INSTALLROOT}/usr/bin/exporter"; \
    \
    find "${INSTALLROOT}/opt/bitnami/scripts" -type f -name "*.sh" -exec chmod 0755 {} +; \
    chgrp -R 0 \
      "${INSTALLROOT}/opt/bitnami" \
      "${INSTALLROOT}/tmp" \
      "${INSTALLROOT}/var/tmp"; \
    chmod -R u+rwX,g+rwX \
      "${INSTALLROOT}/opt/bitnami" \
      "${INSTALLROOT}/tmp" \
      "${INSTALLROOT}/var/tmp"; \
    \
    : "validate installed exporter without a login shell or /dev/null redirects"; \
    chroot --userspec=1001:0 "${INSTALLROOT}" /usr/bin/env -i \
      HOME=/tmp \
      PATH=/opt/bitnami/nginx-exporter/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
      /bin/bash -c 'command -v nginx-prometheus-exporter; command -v exporter; nginx-prometheus-exporter --version || nginx-prometheus-exporter --help'; \
    chroot --userspec=12345:0 "${INSTALLROOT}" /usr/bin/env -i \
      HOME=/tmp \
      PATH=/opt/bitnami/nginx-exporter/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
      /bin/bash -c 'command -v nginx-prometheus-exporter; command -v exporter; nginx-prometheus-exporter --version || nginx-prometheus-exporter --help'; \
    \
    rm -f \
      "${INSTALLROOT}/usr/bin/tdnf" \
      "${INSTALLROOT}/usr/bin/dnf" \
      "${INSTALLROOT}/usr/bin/yum" \
      "${INSTALLROOT}/usr/bin/microdnf" \
      "${INSTALLROOT}/usr/bin/rpm" \
      "${INSTALLROOT}/usr/bin/rpm2cpio" \
      "${INSTALLROOT}/usr/bin/rpmbuild" \
      "${INSTALLROOT}/bin/rpm" \
      "${INSTALLROOT}/sbin/tdnf" \
      "${INSTALLROOT}/sbin/dnf" \
      "${INSTALLROOT}/sbin/yum"; \
    rm -rf \
      "${INSTALLROOT}/etc/yum.repos.d" \
      "${INSTALLROOT}/etc/dnf" \
      "${INSTALLROOT}/etc/tdnf" \
      "${INSTALLROOT}/var/cache/tdnf" \
      "${INSTALLROOT}/var/cache/dnf" \
      "${INSTALLROOT}/var/cache/yum" \
      "${INSTALLROOT}/var/lib/tdnf" \
      "${INSTALLROOT}/var/lib/dnf" \
      "${INSTALLROOT}/var/lib/rpm" \
      "${INSTALLROOT}/usr/share/doc" \
      "${INSTALLROOT}/usr/share/man" \
      "${INSTALLROOT}/usr/share/info" \
      "${INSTALLROOT}/usr/share/bash-completion" \
      "${INSTALLROOT}/tmp"/* \
      "${INSTALLROOT}/var/tmp"/*; \
    find "${INSTALLROOT}" -perm /6000 -type f -exec chmod a-s {} + || true; \
    printf '%s\n' \
      "APP_NAME=nginx-exporter" \
      "APP_VERSION=${APP_VERSION}" \
      "IMAGE_REVISION=${IMAGE_REVISION}" \
      "NICEOS_CONTAINER_STREAM=${NICEOS_VERSION}" \
      "BITNAMI_COMPAT_REFERENCE=bitnami/nginx-exporter/1/debian-12" \
      > "${INSTALLROOT}/.niceos-image-release"

FROM scratch

ARG NICEOS_VERSION=13
ARG NICEOS_BASE_IMAGE=docker.io/niceos/niceos-container-base:13
ARG APP_VERSION=1.5.1
ARG IMAGE_REVISION=1
ARG BUILD_DATE=1970-01-01T00:00:00Z
ARG VCS_REF=unknown
ARG TARGETARCH=amd64
ARG INSTALLROOT=/niceos-rootfs

COPY --from=rootfs ${INSTALLROOT}/ /

LABEL org.opencontainers.image.title="nginx-exporter" \
      org.opencontainers.image.description="NiceOS.Container based NGINX Prometheus Exporter image and Bitnami-compatible migration target" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/niceos-containers/containers/tree/main/apps/nginx-exporter" \
      org.opencontainers.image.documentation="https://github.com/niceos-containers/containers/tree/main/apps/nginx-exporter" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.base.name="${NICEOS_BASE_IMAGE}" \
      org.opencontainers.image.vendor="NiceSOFT" \
      ru.niceos.container.stream="${NICEOS_VERSION}" \
      ru.niceos.container.app="nginx-exporter" \
      ru.niceos.container.bitnami-compatible="true" \
      ru.niceos.container.bitnami-reference="bitnami/nginx-exporter/1/debian-12" \
      ru.niceos.container.layout.opt-bitnami="true" \
      ru.niceos.container.default-user="1001"

ENV APP_VERSION="${APP_VERSION}" \
    BITNAMI_APP_NAME="nginx-exporter" \
    BITNAMI_IMAGE_VERSION="${APP_VERSION}-niceos${NICEOS_VERSION}-r${IMAGE_REVISION}" \
    BITNAMI_ROOT_DIR="/opt/bitnami" \
    HOME="/" \
    IMAGE_REVISION="${IMAGE_REVISION}" \
    NICEOS_CONTAINER_STREAM="${NICEOS_VERSION}" \
    OS_ARCH="${TARGETARCH}" \
    OS_FLAVOUR="niceos-container-13" \
    OS_NAME="linux" \
    PATH="/opt/bitnami/nginx-exporter/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

EXPOSE 9113
WORKDIR /opt/bitnami/nginx-exporter
USER 1001

ENTRYPOINT ["nginx-prometheus-exporter"]
