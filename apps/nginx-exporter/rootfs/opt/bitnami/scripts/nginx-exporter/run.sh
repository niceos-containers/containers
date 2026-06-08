#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

. /opt/bitnami/scripts/nginx-exporter-env.sh

exec nginx-prometheus-exporter "$@"
