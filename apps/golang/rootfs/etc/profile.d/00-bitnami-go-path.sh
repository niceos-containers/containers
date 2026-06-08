# NiceOS Golang Bitnami-compatible PATH
# SPDX-License-Identifier: Apache-2.0

case ":${PATH:-}:" in
    *:/go/bin:*) ;;
    *) PATH="/go/bin:${PATH:-}" ;;
esac

case ":${PATH:-}:" in
    *:/opt/bitnami/go/bin:*) ;;
    *) PATH="/opt/bitnami/go/bin:${PATH:-}" ;;
esac

export PATH
