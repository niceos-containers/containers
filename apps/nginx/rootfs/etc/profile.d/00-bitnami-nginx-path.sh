# SPDX-License-Identifier: Apache-2.0
# Keep Bitnami-compatible command paths deterministic.
case ":${PATH}:" in
  *:/opt/bitnami/nginx/sbin:*) ;;
  *) PATH="/opt/bitnami/nginx/sbin:${PATH}" ;;
esac
case ":${PATH}:" in
  *:/opt/bitnami/common/bin:*) ;;
  *) PATH="/opt/bitnami/common/bin:${PATH}" ;;
esac
export PATH
