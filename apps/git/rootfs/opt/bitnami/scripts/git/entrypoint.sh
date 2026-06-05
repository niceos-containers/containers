#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0
#
# NiceOS adaptation:
# - Preserves the historical Bitnami Git runtime contract.
# - Keeps NSS wrapper support for arbitrary UID / OpenShift-style execution.
# - Generates SSH host keys when /etc/ssh is writable.
# - Skips SSH host key generation on read-only rootfs instead of failing.
#
# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
#set -o xtrace

# Load libraries
. /opt/bitnami/scripts/libbitnami.sh
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libos.sh

print_welcome_page

# Keep Bitnami-compatible PATH even when the parent image or runtime changed it.
export PATH="/opt/bitnami/git/bin:/opt/bitnami/common/bin:${PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"

niceos_warn() {
    if command -v warn >/dev/null 2>&1; then
        warn "$@"
    else
        echo "WARN  ==> $*" >&2
    fi
}

# Configure NSS wrapper for arbitrary UID execution.
#
# This is required for OpenShift/Kubernetes-style arbitrary UID containers,
# where the process UID may not exist in /etc/passwd.
if ! am_i_root; then
    export LNAME="${LNAME:-git}"

    NSS_WRAPPER_LIB="${NSS_WRAPPER_LIB:-/opt/bitnami/common/lib/libnss_wrapper.so}"

    if [[ -f "$NSS_WRAPPER_LIB" ]]; then
        if ! user_exists "$(id -u)"; then
            # shellcheck disable=SC2155
            export NSS_WRAPPER_PASSWD="$(mktemp)"
            # shellcheck disable=SC2155
            export NSS_WRAPPER_GROUP="$(mktemp)"

            echo "git:x:$(id -u):$(id -g):Git:${HOME:-/}:/bin/false" > "$NSS_WRAPPER_PASSWD"
            echo "git:x:$(id -g):" > "$NSS_WRAPPER_GROUP"

            if [[ -n "${LD_PRELOAD:-}" ]]; then
                export LD_PRELOAD="${NSS_WRAPPER_LIB}:${LD_PRELOAD}"
            else
                export LD_PRELOAD="${NSS_WRAPPER_LIB}"
            fi
        fi
    else
        niceos_warn "NSS wrapper library not found at ${NSS_WRAPPER_LIB}; arbitrary UID name lookup may be unavailable"
    fi
fi

generate_ssh_host_key_if_needed() {
    local key_type="$1"
    local key_file="$2"

    if [[ -f "$key_file" ]]; then
        return 0
    fi

    if [[ ! -d /etc/ssh ]]; then
        niceos_warn "/etc/ssh does not exist; skipping ${key_type} SSH host key generation"
        return 0
    fi

    if [[ ! -w /etc/ssh ]]; then
        niceos_warn "/etc/ssh is not writable; skipping ${key_type} SSH host key generation"
        return 0
    fi

    ssh-keygen -q -t "$key_type" -f "$key_file" -N "" <<<y >/dev/null 2>&1
}

# Generate new SSH host key pairs if they do not exist.
#
# Bitnami historically generates these at container start. NiceOS keeps the same
# behavior for writable rootfs, but does not fail in read-only rootfs mode.
generate_ssh_host_key_if_needed rsa     /etc/ssh/ssh_host_rsa_key
generate_ssh_host_key_if_needed ecdsa   /etc/ssh/ssh_host_ecdsa_key
generate_ssh_host_key_if_needed ed25519 /etc/ssh/ssh_host_ed25519_key

[ "$#" -eq 0 ] || exec "$@"
