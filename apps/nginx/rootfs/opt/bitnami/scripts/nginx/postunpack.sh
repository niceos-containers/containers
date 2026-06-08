#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail

. /opt/bitnami/scripts/nginx-env.sh
. /opt/bitnami/scripts/libnginx.sh

nginx_prepare_dirs
nginx_copy_default_conf
ln -sf /dev/stdout "${NGINX_LOGS_DIR}/access.log" || true
ln -sf /dev/stderr "${NGINX_LOGS_DIR}/error.log" || true
chmod -R g+rwX "${BITNAMI_ROOT_DIR}" "${BITNAMI_VOLUME_DIR}" /app /tmp /var/tmp /run 2>/dev/null || true
