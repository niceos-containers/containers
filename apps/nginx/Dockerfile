# syntax=docker/dockerfile:1.7
# SPDX-License-Identifier: Apache-2.0

ARG NICEOS_VERSION=13
ARG NICEOS_BASE_IMAGE=docker.io/niceos/niceos-container-base:13
ARG APP_VERSION=1.31.1
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

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG NICEOS_APP_PACKAGES="niceos-release niceos-repos filesystem bash coreutils findutils sed grep gawk ca-certificates openssl nss_wrapper procps-ng gettext-envsubst niceos-bitnami-compat-scripts nginx"

RUN set -eux; \
    mkdir -p "${INSTALLROOT}"; \
    tdnf -y \
        --installroot="${INSTALLROOT}" \
        --releasever="${NICEOS_VERSION}" \
        --setopt=install_weak_deps=0 \
        --setopt=tsflags=nodocs \
        install ${NICEOS_APP_PACKAGES}; \
    forbidden="$(rpm --root "${INSTALLROOT}" -qa | grep -E '^(gcc|gcc-c\+\+|glibc-devel|binutils|make|cmake|ninja|meson|flex|m4|perl|niceos-perl-macros|mpc-devel)-' || true)"; \
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
        "${INSTALLROOT}/etc/nginx" \
        "${INSTALLROOT}/opt/bitnami/common/bin" \
        "${INSTALLROOT}/opt/bitnami/common/lib" \
        "${INSTALLROOT}/opt/bitnami/nginx/sbin" \
        "${INSTALLROOT}/opt/bitnami/nginx/conf" \
        "${INSTALLROOT}/opt/bitnami/nginx/conf.default" \
        "${INSTALLROOT}/opt/bitnami/nginx/conf/server_blocks" \
        "${INSTALLROOT}/opt/bitnami/nginx/conf/stream_server_blocks" \
        "${INSTALLROOT}/opt/bitnami/nginx/conf/context.d/main" \
        "${INSTALLROOT}/opt/bitnami/nginx/conf/context.d/events" \
        "${INSTALLROOT}/opt/bitnami/nginx/conf/context.d/http" \
        "${INSTALLROOT}/opt/bitnami/nginx/logs" \
        "${INSTALLROOT}/opt/bitnami/nginx/tmp" \
        "${INSTALLROOT}/opt/bitnami/nginx/tmp/client_body_temp" \
        "${INSTALLROOT}/opt/bitnami/nginx/tmp/proxy_temp" \
        "${INSTALLROOT}/opt/bitnami/nginx/tmp/fastcgi_temp" \
        "${INSTALLROOT}/opt/bitnami/nginx/tmp/uwsgi_temp" \
        "${INSTALLROOT}/opt/bitnami/nginx/tmp/scgi_temp" \
        "${INSTALLROOT}/bitnami/nginx" \
        "${INSTALLROOT}/app" \
        "${INSTALLROOT}/tmp" \
        "${INSTALLROOT}/var/tmp" \
        "${INSTALLROOT}/var/log/nginx" \
        "${INSTALLROOT}/var/cache/nginx" \
        "${INSTALLROOT}/run/nginx"; \
    \
    if [ -x "${INSTALLROOT}/usr/sbin/nginx" ]; then \
        ln -sfn /usr/sbin/nginx "${INSTALLROOT}/opt/bitnami/nginx/sbin/nginx"; \
    elif [ -x "${INSTALLROOT}/usr/bin/nginx" ]; then \
        ln -sfn /usr/bin/nginx "${INSTALLROOT}/opt/bitnami/nginx/sbin/nginx"; \
    else \
        echo "Unable to locate nginx binary from RPM nginx" >&2; \
        exit 1; \
    fi; \
    \
    if [ -x "${INSTALLROOT}/usr/bin/render-template" ]; then \
        ln -sfn /usr/bin/render-template "${INSTALLROOT}/opt/bitnami/common/bin/render-template"; \
    fi; \
    \
    nss_wrapper="$(find "${INSTALLROOT}/usr" -name 'libnss_wrapper.so*' -type f -print -quit || true)"; \
    if [ -n "${nss_wrapper}" ]; then \
        ln -sfn "/${nss_wrapper#${INSTALLROOT}/}" "${INSTALLROOT}/opt/bitnami/common/lib/libnss_wrapper.so"; \
    fi; \
    \
    cp -a "${INSTALLROOT}/opt/bitnami/nginx/conf.default/." "${INSTALLROOT}/opt/bitnami/nginx/conf/"; \
    for file in mime.types fastcgi.conf fastcgi_params scgi_params uwsgi_params koi-utf koi-win win-utf; do \
        if [ -e "${INSTALLROOT}/etc/nginx/${file}" ] && [ ! -e "${INSTALLROOT}/opt/bitnami/nginx/conf/${file}" ]; then \
            cp -a "${INSTALLROOT}/etc/nginx/${file}" "${INSTALLROOT}/opt/bitnami/nginx/conf/${file}"; \
        fi; \
    done; \
    rm -f "${INSTALLROOT}/etc/nginx/nginx.conf"; \
    ln -sfn /opt/bitnami/nginx/conf/nginx.conf "${INSTALLROOT}/etc/nginx/nginx.conf"; \
    \
    find "${INSTALLROOT}/opt/bitnami/scripts" -type f -name "*.sh" -exec chmod 0755 {} +; \
    chroot "${INSTALLROOT}" /opt/bitnami/scripts/nginx/postunpack.sh; \
    \
    rm -f \
        "${INSTALLROOT}/opt/bitnami/nginx/logs/access.log" \
        "${INSTALLROOT}/opt/bitnami/nginx/logs/error.log" \
        "${INSTALLROOT}/var/log/nginx/access.log" \
        "${INSTALLROOT}/var/log/nginx/error.log"; \
    : > "${INSTALLROOT}/opt/bitnami/nginx/logs/access.log"; \
    : > "${INSTALLROOT}/opt/bitnami/nginx/logs/error.log"; \
    ln -sfn /opt/bitnami/nginx/logs/access.log "${INSTALLROOT}/var/log/nginx/access.log"; \
    ln -sfn /opt/bitnami/nginx/logs/error.log "${INSTALLROOT}/var/log/nginx/error.log"; \
    \
    chgrp -R 0 \
        "${INSTALLROOT}/etc/nginx" \
        "${INSTALLROOT}/opt/bitnami" \
        "${INSTALLROOT}/bitnami" \
        "${INSTALLROOT}/app" \
        "${INSTALLROOT}/tmp" \
        "${INSTALLROOT}/var/tmp" \
        "${INSTALLROOT}/var/log/nginx" \
        "${INSTALLROOT}/var/cache/nginx" \
        "${INSTALLROOT}/run"; \
    chown -R 1001:0 \
        "${INSTALLROOT}/opt/bitnami/nginx/logs" \
        "${INSTALLROOT}/opt/bitnami/nginx/tmp" \
        "${INSTALLROOT}/bitnami/nginx" \
        "${INSTALLROOT}/app" \
        "${INSTALLROOT}/var/log/nginx" \
        "${INSTALLROOT}/var/cache/nginx" \
        "${INSTALLROOT}/run/nginx"; \
    chmod -R u+rwX,g+rwX \
        "${INSTALLROOT}/etc/nginx" \
        "${INSTALLROOT}/opt/bitnami" \
        "${INSTALLROOT}/bitnami" \
        "${INSTALLROOT}/app" \
        "${INSTALLROOT}/tmp" \
        "${INSTALLROOT}/var/tmp" \
        "${INSTALLROOT}/var/log/nginx" \
        "${INSTALLROOT}/var/cache/nginx" \
        "${INSTALLROOT}/run"; \
    \
    chroot --userspec=1001:0 "${INSTALLROOT}" /bin/bash -lc ': > /opt/bitnami/nginx/tmp/.writable && rm -f /opt/bitnami/nginx/tmp/.writable'; \
    chroot --userspec=12345:0 "${INSTALLROOT}" /bin/bash -lc ': > /opt/bitnami/nginx/tmp/.writable-arbitrary && rm -f /opt/bitnami/nginx/tmp/.writable-arbitrary'; \
    chroot --userspec=1001:0 "${INSTALLROOT}" nginx -t; \
    chroot --userspec=1001:0 "${INSTALLROOT}" nginx -t -c /opt/bitnami/nginx/conf/nginx.conf; \
    \
    rm -f \
        "${INSTALLROOT}/opt/bitnami/nginx/tmp/nginx.pid" \
        "${INSTALLROOT}/opt/bitnami/nginx/tmp/nginx.pid.oldbin" \
        "${INSTALLROOT}/run/nginx.pid" \
        "${INSTALLROOT}/run/nginx/nginx.pid" \
        "${INSTALLROOT}/var/run/nginx.pid" \
        "${INSTALLROOT}/var/run/nginx/nginx.pid"; \
    if find "${INSTALLROOT}/opt/bitnami/nginx/tmp" -maxdepth 1 -name 'nginx.pid*' -print -quit | grep -q .; then \
        echo "Build-time nginx pid files must not remain in final image:" >&2; \
        find "${INSTALLROOT}/opt/bitnami/nginx/tmp" -maxdepth 1 -name 'nginx.pid*' -ls >&2; \
        exit 1; \
    fi; \
    \
    rm -f \
        "${INSTALLROOT}/opt/bitnami/nginx/logs/access.log" \
        "${INSTALLROOT}/opt/bitnami/nginx/logs/error.log"; \
    ln -sfn /dev/stdout "${INSTALLROOT}/opt/bitnami/nginx/logs/access.log"; \
    ln -sfn /dev/stderr "${INSTALLROOT}/opt/bitnami/nginx/logs/error.log"; \
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
        "APP_NAME=nginx" \
        "APP_VERSION=${APP_VERSION}" \
        "IMAGE_REVISION=${IMAGE_REVISION}" \
        "NICEOS_CONTAINER_STREAM=${NICEOS_VERSION}" \
        "BITNAMI_COMPAT_REFERENCE=bitnami/nginx/1.31/debian-12" \
        > "${INSTALLROOT}/.niceos-image-release"

FROM scratch

ARG NICEOS_VERSION=13
ARG NICEOS_BASE_IMAGE=docker.io/niceos/niceos-container-base:13
ARG APP_VERSION=1.31.1
ARG IMAGE_REVISION=1
ARG BUILD_DATE=1970-01-01T00:00:00Z
ARG VCS_REF=unknown
ARG TARGETARCH=amd64
ARG INSTALLROOT=/niceos-rootfs

COPY --from=rootfs ${INSTALLROOT}/ /

LABEL org.opencontainers.image.title="nginx" \
      org.opencontainers.image.description="NiceOS.Container based NGINX image and Bitnami-compatible migration target" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/niceos-containers/containers/tree/main/apps/nginx" \
      org.opencontainers.image.documentation="https://github.com/niceos-containers/containers/tree/main/apps/nginx" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.base.name="${NICEOS_BASE_IMAGE}" \
      org.opencontainers.image.vendor="NiceSOFT" \
      ru.niceos.container.stream="${NICEOS_VERSION}" \
      ru.niceos.container.app="nginx" \
      ru.niceos.container.bitnami-compatible="true" \
      ru.niceos.container.bitnami-reference="bitnami/nginx/1.31/debian-12" \
      ru.niceos.container.layout.opt-bitnami="true" \
      ru.niceos.container.default-user="1001"

ENV APP_VERSION="${APP_VERSION}" \
    BITNAMI_APP_NAME="nginx" \
    BITNAMI_IMAGE_VERSION="${APP_VERSION}-niceos${NICEOS_VERSION}-r${IMAGE_REVISION}" \
    BITNAMI_ROOT_DIR="/opt/bitnami" \
    BITNAMI_VOLUME_DIR="/bitnami" \
    HOME="/" \
    IMAGE_REVISION="${IMAGE_REVISION}" \
    NICEOS_CONTAINER_STREAM="${NICEOS_VERSION}" \
    NGINX_HTTP_PORT_NUMBER="8080" \
    NGINX_HTTPS_PORT_NUMBER="8443" \
    NGINX_ENABLE_STREAM="no" \
    NGINX_ENABLE_ABSOLUTE_REDIRECT="no" \
    NGINX_ENABLE_PORT_IN_REDIRECT="no" \
    NGINX_WORKER_PROCESSES="auto" \
    NSS_WRAPPER_LIB="/opt/bitnami/common/lib/libnss_wrapper.so" \
    OS_ARCH="${TARGETARCH}" \
    OS_FLAVOUR="niceos-container-13" \
    OS_NAME="linux" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/nginx/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

EXPOSE 8080 8443
STOPSIGNAL SIGQUIT
WORKDIR /app
USER 1001
ENTRYPOINT ["/opt/bitnami/scripts/nginx/entrypoint.sh"]
CMD ["/opt/bitnami/scripts/nginx/run.sh"]
