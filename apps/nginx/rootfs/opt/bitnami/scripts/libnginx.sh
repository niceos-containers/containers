#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# NiceOS app-specific NGINX compatibility helpers.
# shellcheck shell=bash

nginx_info() { echo "nginx ${*}"; }
nginx_warn() { echo "nginx WARN ${*}" >&2; }
nginx_debug() { [ "${BITNAMI_DEBUG:-false}" = "true" ] && echo "nginx DEBUG ${*}" >&2 || true; }

nginx_is_yes() {
    case "${1:-}" in
        y|Y|yes|YES|true|TRUE|1) return 0 ;;
        *) return 1 ;;
    esac
}

nginx_am_i_root() {
    [ "$(id -u)" = "0" ]
}

nginx_is_writable() {
    local target="${1:?path required}"
    if [ -e "$target" ]; then
        [ -w "$target" ]
    else
        [ -w "$(dirname "$target")" ]
    fi
}

nginx_validate_port() {
    local name="${1:?name required}"
    local value="${2:-}"
    [ -z "$value" ] && return 0
    if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 1 ] || [ "$value" -gt 65535 ]; then
        echo "Invalid ${name}: ${value}" >&2
        return 1
    fi
}

nginx_validate() {
    nginx_validate_port NGINX_HTTP_PORT_NUMBER "${NGINX_HTTP_PORT_NUMBER:-}"
    nginx_validate_port NGINX_HTTPS_PORT_NUMBER "${NGINX_HTTPS_PORT_NUMBER:-}"
    if [ "${NGINX_WORKER_PROCESSES:-auto}" != "auto" ] && ! [[ "${NGINX_WORKER_PROCESSES}" =~ ^[0-9]+$ ]]; then
        echo "Invalid NGINX_WORKER_PROCESSES: ${NGINX_WORKER_PROCESSES}" >&2
        return 1
    fi
}

nginx_prepare_dirs() {
    local dirs=(
        "$NGINX_CONF_DIR"
        "$NGINX_SERVER_BLOCKS_DIR"
        "$NGINX_STREAM_SERVER_BLOCKS_DIR"
        "$NGINX_CONF_DIR/context.d/main"
        "$NGINX_CONF_DIR/context.d/events"
        "$NGINX_CONF_DIR/context.d/http"
        "$NGINX_LOGS_DIR"
        "$NGINX_TMP_DIR"
        "$NGINX_TMP_DIR/client_body"
        "$NGINX_TMP_DIR/proxy"
        "$NGINX_TMP_DIR/fastcgi"
        "$NGINX_TMP_DIR/uwsgi"
        "$NGINX_TMP_DIR/scgi"
        "$BITNAMI_VOLUME_DIR/nginx"
        "/app"
    )
    local d
    for d in "${dirs[@]}"; do
        if [ -d "$d" ]; then
            chmod g+rwX "$d" 2>/dev/null || true
        elif nginx_is_writable "$(dirname "$d")"; then
            mkdir -p "$d" && chmod g+rwX "$d" || true
        fi
    done
}

nginx_copy_default_conf() {
    if [ ! -d "$NGINX_DEFAULT_CONF_DIR" ]; then
        nginx_warn "default configuration directory does not exist: $NGINX_DEFAULT_CONF_DIR"
        return 0
    fi
    if nginx_is_writable "$NGINX_CONF_DIR"; then
        cp -an "$NGINX_DEFAULT_CONF_DIR"/. "$NGINX_CONF_DIR"/ 2>/dev/null || true
    else
        nginx_debug "configuration directory is not writable: $NGINX_CONF_DIR"
    fi
}

nginx_patch_default_conf() {
    local conf="$NGINX_CONF_FILE"
    local default_block="$NGINX_SERVER_BLOCKS_DIR/default.conf"

    if [ -f "$conf" ] && nginx_is_writable "$conf"; then
        sed -i "s/^worker_processes .*/worker_processes ${NGINX_WORKER_PROCESSES};/" "$conf" || true
    fi

    if [ -f "$default_block" ] && nginx_is_writable "$default_block"; then
        sed -i -E "s/listen 0\.0\.0\.0:[0-9]+;/listen 0.0.0.0:${NGINX_HTTP_PORT_NUMBER};/" "$default_block" || true
        if nginx_is_yes "$NGINX_ENABLE_ABSOLUTE_REDIRECT"; then
            sed -i 's/absolute_redirect off;/absolute_redirect on;/' "$default_block" || true
        else
            sed -i 's/absolute_redirect on;/absolute_redirect off;/' "$default_block" || true
        fi
        if nginx_is_yes "$NGINX_ENABLE_PORT_IN_REDIRECT"; then
            sed -i 's/port_in_redirect off;/port_in_redirect on;/' "$default_block" || true
        else
            sed -i 's/port_in_redirect on;/port_in_redirect off;/' "$default_block" || true
        fi
    fi
}

nginx_generate_sample_certs() {
    local cert_dir="$NGINX_CONF_DIR/bitnami/certs"
    local crt="$cert_dir/tls.crt"
    local key="$cert_dir/tls.key"
    if [ -f "$crt" ] && [ -f "$key" ]; then
        return 0
    fi
    if ! command -v openssl >/dev/null 2>&1 || ! nginx_is_writable "$NGINX_CONF_DIR"; then
        return 0
    fi
    mkdir -p "$cert_dir" || return 0
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -subj "/CN=localhost" \
        -keyout "$key" -out "$crt" >/dev/null 2>&1 || true
    chmod g+rwX "$cert_dir" "$crt" "$key" 2>/dev/null || true
}

nginx_enable_https_if_requested() {
    local template="/opt/bitnami/scripts/nginx/bitnami-templates/default-https-server-block.conf"
    local target="$NGINX_SERVER_BLOCKS_DIR/default-https-server-block.conf"
    if [ -z "${NGINX_HTTPS_PORT_NUMBER:-}" ]; then
        return 0
    fi
    if [ -f "$NGINX_CONF_DIR/bitnami/certs/tls.crt" ] && [ -f "$NGINX_CONF_DIR/bitnami/certs/tls.key" ] && [ -f "$template" ] && [ ! -f "$target" ] && nginx_is_writable "$target"; then
        cp "$template" "$target" || true
        sed -i -E "s/listen 0\.0\.0\.0:[0-9]+ ssl;/listen 0.0.0.0:${NGINX_HTTPS_PORT_NUMBER} ssl;/" "$target" || true
    fi
}

nginx_custom_init_scripts() {
    local init_dir="/docker-entrypoint-init.d"
    [ -d "$init_dir" ] || return 0
    local f
    for f in "$init_dir"/*; do
        [ -e "$f" ] || continue
        case "$f" in
            *.sh) nginx_info "Running init script $f"; . "$f" ;;
            *) nginx_info "Ignoring init file $f" ;;
        esac
    done
}

nginx_initialize() {
    nginx_prepare_dirs
    nginx_copy_default_conf
    nginx_patch_default_conf
    nginx_generate_sample_certs
    nginx_enable_https_if_requested
    nginx_custom_init_scripts
    "${NGINX_SBIN_DIR}/nginx" -t -c "$NGINX_CONF_FILE"
}

nginx_stop() {
    if [ -f "${NGINX_PID_FILE:-}" ]; then
        "${NGINX_SBIN_DIR}/nginx" -s quit -c "$NGINX_CONF_FILE" >/dev/null 2>&1 || true
    fi
}
