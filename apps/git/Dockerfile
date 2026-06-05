# syntax=docker/dockerfile:1.7

ARG NICEOS_BASE_IMAGE=docker.io/niceosapps/niceos-container-base:13

FROM ${NICEOS_BASE_IMAGE} AS installer

ARG NICEOS_VERSION=13

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

RUN mkdir -p /rootfs /run /var /tmp /var/tmp && \
    chmod 1777 /tmp /var/tmp && \
    ln -sfn ../run /var/run && \
    tdnf --installroot /rootfs --releasever "${NICEOS_VERSION}" -y \
      --setopt=install_weak_deps=False \
      --setopt=tsflags=nodocs \
      install \
        filesystem \
        niceos-release \
        niceos-bitnami-compat-scripts \
        glibc \
        bash \
        coreutils \
        findutils \
        grep \
        sed \
        gawk \
        tzdata \
        ca-certificates \
        curl \
        git \
        git-lfs \
        openssh-clients \
        nss_wrapper \
        procps-ng \
        gzip \
        tar \
        less && \
    tdnf --installroot /rootfs clean all && \
    rm -rf \
      /rootfs/var/cache/tdnf \
      /rootfs/var/cache/dnf \
      /rootfs/var/cache/yum

# App-specific Bitnami-compatible files:
#   /opt/bitnami/scripts/git/entrypoint.sh
#   /etc/profile.d/00-bitnami-path.sh
#   /etc/gitconfig
COPY rootfs /rootfs/

RUN mkdir -p \
      /rootfs/opt/bitnami/common/bin \
      /rootfs/opt/bitnami/common/lib \
      /rootfs/opt/bitnami/git/bin \
      /rootfs/bitnami/git \
      /rootfs/etc/ssh \
      /rootfs/etc/profile.d \
      /rootfs/tmp \
      /rootfs/var/tmp \
      /rootfs/run && \
    chmod 1777 /rootfs/tmp /rootfs/var/tmp && \
    for binary in \
      git \
      git-lfs \
      git-receive-pack \
      git-shell \
      git-upload-archive \
      git-upload-pack \
      scalar \
    ; do \
      if [ -x "/rootfs/usr/bin/${binary}" ]; then \
        ln -sfn "/usr/bin/${binary}" "/rootfs/opt/bitnami/git/bin/${binary}"; \
      elif [ -x "/rootfs/usr/libexec/git-core/${binary}" ]; then \
        ln -sfn "/usr/libexec/git-core/${binary}" "/rootfs/opt/bitnami/git/bin/${binary}"; \
      fi; \
    done && \
    nss_wrapper_lib="$( { \
      find /rootfs/usr/lib /rootfs/usr/lib64 \
        \( -name 'libnss_wrapper.so.0' -o -name 'libnss_wrapper.so' \) \
        2>/dev/null || true; \
    } | head -n1 )" && \
    test -n "${nss_wrapper_lib}" && \
    ln -sfn "${nss_wrapper_lib#/rootfs}" /rootfs/opt/bitnami/common/lib/libnss_wrapper.so && \
    rm -f /rootfs/etc/ssh/ssh_host_* && \
    chmod g+w /rootfs/etc/ssh && \
    chmod 0644 \
      /rootfs/.bash_profile \
      /rootfs/etc/profile.d/00-bitnami-path.sh \
      /rootfs/etc/gitconfig && \
    chmod 0755 /rootfs/opt/bitnami/scripts/*.sh /rootfs/opt/bitnami/scripts/git/*.sh && \
    chmod -R g=u \
      /rootfs/opt/bitnami \
      /rootfs/bitnami \
      /rootfs/etc/ssh \
      /rootfs/tmp \
      /rootfs/var/tmp \
      /rootfs/run

RUN rm -rf \
      /rootfs/etc/yum.repos.d \
      /rootfs/etc/pki/rpm-gpg \
      /rootfs/usr/share/man \
      /rootfs/usr/share/info \
      /rootfs/usr/share/doc \
      /rootfs/tmp/* \
      /rootfs/var/tmp/* && \
    rm -f \
      /rootfs/usr/bin/tdnf \
      /rootfs/usr/bin/dnf \
      /rootfs/usr/bin/yum \
      /rootfs/usr/sbin/sshd \
      /rootfs/usr/bin/systemctl \
      /rootfs/usr/bin/gcc \
      /rootfs/usr/bin/make \
      /rootfs/usr/bin/cmake \
      /rootfs/usr/bin/ninja || true && \
    find /rootfs -perm /6000 -type f -exec chmod a-s {} \; || true

FROM scratch

ARG TARGETARCH=amd64
ARG NICEOS_VERSION=13
ARG NICEOS_BASE_IMAGE=docker.io/niceosapps/niceos-container-base:13
ARG APP_VERSION=2.54.0
ARG IMAGE_REVISION=1
ARG BUILD_DATE=unknown
ARG VCS_REF=unknown

LABEL org.opencontainers.image.title="NiceOS Git" \
      org.opencontainers.image.description="NiceOS.Container based Git image with Bitnami-compatible runtime contract, Git LFS, arbitrary UID support, read-only rootfs support, OpenSSH client tooling and RPM-controlled NiceOS provenance" \
      org.opencontainers.image.vendor="NiceSOFT" \
      org.opencontainers.image.authors="NiceSOFT LLC / ООО \"НАЙС СОФТ ГРУПП\" 5024245440 <niceos@ncsgp.ru>" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://specs.niceos.ru/niceos-containers/app-git" \
      org.opencontainers.image.url="https://hub.docker.com/r/niceos/git" \
      org.opencontainers.image.documentation="https://hub.docker.com/r/niceos/git" \
      org.opencontainers.image.licenses="Apache-2.0 AND GPL-2.0-only AND MIT AND BSD-3-Clause" \
      org.opencontainers.image.base.name="${NICEOS_BASE_IMAGE}" \
      org.opencontainers.image.ref.name="${APP_VERSION}-niceos${NICEOS_VERSION}-r${IMAGE_REVISION}" \
      org.opencontainers.image.name="docker.io/niceos/git" \
      org.opencontainers.image.summary="NiceOS Git container for Bitnami-compatible migration workflows" \
      org.opencontainers.image.component="git" \
      org.opencontainers.image.documentation.source="README.md" \
      ru.niceos.image.product="NiceOS Application Containers" \
      ru.niceos.image.vendor="NiceSOFT" \
      ru.niceos.image.stream="NiceOS.Container" \
      ru.niceos.image.releasever="${NICEOS_VERSION}" \
      ru.niceos.image.kind="bitnami-compatible-app" \
      ru.niceos.image.namespace="niceos" \
      ru.niceos.image.repository="git" \
      ru.niceos.image.fullname="docker.io/niceos/git" \
      ru.niceos.image.app="git" \
      ru.niceos.image.app.version="${APP_VERSION}" \
      ru.niceos.image.revision="${IMAGE_REVISION}" \
      ru.niceos.image.tag="${APP_VERSION}-niceos${NICEOS_VERSION}-r${IMAGE_REVISION}" \
      ru.niceos.image.compatibility.reference="bitnami/git/2/debian-12" \
      ru.niceos.image.compatibility.mode="migration-target" \
      ru.niceos.image.compatibility.contract="/opt/bitnami,/bitnami,BITNAMI_*,arbitrary-uid,nss-wrapper,git-lfs,Helm-values-compatible" \
      ru.niceos.image.runtime.git.version="${APP_VERSION}" \
      ru.niceos.image.runtime.git-lfs.version="3.7.1" \
      ru.niceos.image.runtime.nss-wrapper="enabled" \
      ru.niceos.image.runtime.arbitrary-uid="supported" \
      ru.niceos.image.runtime.readonly-rootfs="supported" \
      ru.niceos.image.runtime.ssh-client="enabled" \
      ru.niceos.image.package-manager="removed-from-runtime" \
      ru.niceos.image.build-tools="removed-from-runtime" \
      ru.niceos.image.os.family="niceos" \
      ru.niceos.image.os.flavour="niceos-container-13"

COPY --from=installer /rootfs /

ENV HOME="/" \
    OS_ARCH="${TARGETARCH}" \
    OS_FLAVOUR="niceos-container-13" \
    OS_NAME="linux" \
    APP_VERSION="${APP_VERSION}" \
    BITNAMI_APP_NAME="git" \
    IMAGE_REVISION="${IMAGE_REVISION}" \
    BITNAMI_ROOT_DIR="/opt/bitnami" \
    BITNAMI_VOLUME_DIR="/bitnami" \
    NSS_WRAPPER_LIB="/opt/bitnami/common/lib/libnss_wrapper.so" \
    PATH="/opt/bitnami/git/bin:/opt/bitnami/common/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ENTRYPOINT ["/opt/bitnami/scripts/git/entrypoint.sh"]
CMD ["/bin/bash"]
