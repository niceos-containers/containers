# SPDX-License-Identifier: Apache-2.0
# NiceOS Bitnami-compatible path for nginx-exporter.

case ":${PATH:-}:" in
  *:/opt/bitnami/nginx-exporter/bin:*) ;;
  *) export PATH="/opt/bitnami/nginx-exporter/bin:${PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}" ;;
esac
