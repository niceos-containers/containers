#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${1:-docker.io/niceos/golang}"
TAG="${2:-1.26.4-niceos13-r1}"
CONTAINER_ENGINE="${CONTAINER_ENGINE:-podman}"
PUSH_LATEST="${PUSH_LATEST:-1}"
PUSH_MINOR="${PUSH_MINOR:-1}"
MINOR_TAG="${MINOR_TAG:-1.26}"

set -x
"${CONTAINER_ENGINE}" push "${IMAGE_NAME}:${TAG}"
if [[ "${PUSH_MINOR}" = "1" ]]; then
  "${CONTAINER_ENGINE}" push "${IMAGE_NAME}:${MINOR_TAG}"
fi
if [[ "${PUSH_LATEST}" = "1" ]]; then
  "${CONTAINER_ENGINE}" push "${IMAGE_NAME}:latest"
fi
set +x

printf '\nPublished image tags for %s\n' "${IMAGE_NAME}"
printf '  immutable: %s:%s\n' "${IMAGE_NAME}" "${TAG}"
[[ "${PUSH_MINOR}" = "1" ]] && printf '  minor:     %s:%s\n' "${IMAGE_NAME}" "${MINOR_TAG}"
[[ "${PUSH_LATEST}" = "1" ]] && printf '  latest:    %s:latest\n' "${IMAGE_NAME}"

if command -v skopeo >/dev/null 2>&1; then
  printf '\nDigest:\n'
  skopeo inspect --format '{{.Digest}}' "docker://${IMAGE_NAME}:${TAG}" || true
fi
