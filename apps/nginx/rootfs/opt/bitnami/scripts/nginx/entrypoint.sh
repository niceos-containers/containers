#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail

. /opt/bitnami/scripts/nginx-env.sh
. /opt/bitnami/scripts/libnginx.sh

setup_nss_wrapper() {
    local uid gid passwd_file group_file
    uid="$(id -u)"
    gid="$(id -g)"
    if getent passwd "$uid" >/dev/null 2>&1; then
        return 0
    fi
    if [ ! -r "$NSS_WRAPPER_LIB" ]; then
        nginx_warn "NSS wrapper library is not readable: $NSS_WRAPPER_LIB"
        return 0
    fi
    passwd_file="${TMPDIR:-/tmp}/passwd.nss_wrapper"
    group_file="${TMPDIR:-/tmp}/group.nss_wrapper"
    if ! touch "$passwd_file" "$group_file" 2>/dev/null; then
        nginx_warn "Cannot create NSS wrapper files; arbitrary UID name resolution may be unavailable"
        return 0
    fi
    printf 'niceos:x:%s:%s:NiceOS arbitrary uid:/app:/sbin/nologin\n' "$uid" "$gid" > "$passwd_file"
    printf 'niceos:x:%s:\n' "$gid" > "$group_file"
    export NSS_WRAPPER_PASSWD="$passwd_file"
    export NSS_WRAPPER_GROUP="$group_file"
    export LD_PRELOAD="$NSS_WRAPPER_LIB${LD_PRELOAD:+:$LD_PRELOAD}"
}

setup_nss_wrapper

if command -v print_welcome_page >/dev/null 2>&1; then
    print_welcome_page || true
fi

nginx_debug "Copying files from $NGINX_DEFAULT_CONF_DIR to $NGINX_CONF_DIR"
nginx_copy_default_conf

if [ "${1:-}" = "/opt/bitnami/scripts/nginx/run.sh" ]; then
    nginx_info "** Starting NGINX setup **"
    /opt/bitnami/scripts/nginx/setup.sh
    nginx_info "** NGINX setup finished! **"
fi

echo ""
exec "$@"
