#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

# This wrapper is intentionally not the default Docker ENTRYPOINT.
# It exists for operators who expect a Bitnami-style script path.
. /opt/bitnami/scripts/nginx-exporter-env.sh

exec nginx-prometheus-exporter "$@"
