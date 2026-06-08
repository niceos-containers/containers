#!/usr/bin/env bash
set -euo pipefail

APP_VERSION="${APP_VERSION:-1.26.4}"
NICEOS_STREAM="${NICEOS_STREAM:-13}"
IMAGE_REVISION="${IMAGE_REVISION:-1}"
GO_RPM_NAME="${GO_RPM_NAME:-go1.26}"
IMAGE_NAME="${IMAGE_NAME:-docker.io/niceos/golang}"
BUILDER_IMAGE="${NICEOS_BUILDER_IMAGE:-docker.io/niceos/niceos-container-base:${NICEOS_STREAM}}"
CONTAINER_ENGINE="${CONTAINER_ENGINE:-podman}"
TAG="${APP_VERSION}-niceos${NICEOS_STREAM}-r${IMAGE_REVISION}"

set -x
"${CONTAINER_ENGINE}" build \
  --format docker \
  --build-arg "APP_VERSION=${APP_VERSION}" \
  --build-arg "NICEOS_STREAM=${NICEOS_STREAM}" \
  --build-arg "IMAGE_REVISION=${IMAGE_REVISION}" \
  --build-arg "GO_RPM_NAME=${GO_RPM_NAME}" \
  --build-arg "NICEOS_BUILDER_IMAGE=${BUILDER_IMAGE}" \
  -t "${IMAGE_NAME}:${TAG}" \
  -t "${IMAGE_NAME}:1.26" \
  -t "${IMAGE_NAME}:latest" \
  .

set +x
printf '\nBuilt:\n  %s:%s\n  %s:1.26\n  %s:latest\n' "${IMAGE_NAME}" "${TAG}" "${IMAGE_NAME}" "${IMAGE_NAME}"
