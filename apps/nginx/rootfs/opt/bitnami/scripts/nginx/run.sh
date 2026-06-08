#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail

. /opt/bitnami/scripts/nginx-env.sh
. /opt/bitnami/scripts/libnginx.sh

nginx_info "** Starting NGINX **"
exec "${NGINX_SBIN_DIR}/nginx" -c "$NGINX_CONF_FILE" -g "daemon off;"
