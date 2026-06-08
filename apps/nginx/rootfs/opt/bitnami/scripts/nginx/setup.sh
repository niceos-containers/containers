#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail

. /opt/bitnami/scripts/nginx-env.sh
. /opt/bitnami/scripts/libnginx.sh

nginx_validate
trap "nginx_stop" EXIT
nginx_initialize
