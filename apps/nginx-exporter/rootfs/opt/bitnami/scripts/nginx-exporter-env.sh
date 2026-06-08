#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# NiceOS helper for shell-based diagnostics. The default container ENTRYPOINT
# intentionally remains the nginx-prometheus-exporter binary.

export BITNAMI_APP_NAME="${BITNAMI_APP_NAME:-nginx-exporter}"
export BITNAMI_ROOT_DIR="${BITNAMI_ROOT_DIR:-/opt/bitnami}"
export PATH="/opt/bitnami/nginx-exporter/bin:${PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"
