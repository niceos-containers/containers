#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

chart_dir="${1:-../chart-nginx/chart}"
image_ref="${2:-docker.io/niceos/nginx-exporter:1.5.1-niceos13-r1}"

registry="${image_ref%%/*}"
repo_tag="${image_ref#*/}"
repository="${repo_tag%:*}"
tag="${repo_tag##*:}"

release="niceos-nginx-exporter-smoke-$$"
namespace="${NICEOS_HELM_NAMESPACE:-default}"
apply="${NICEOS_HELM_APPLY:-0}"

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is required" >&2
  exit 1
fi

if [ ! -d "${chart_dir}" ]; then
  echo "Chart directory does not exist: ${chart_dir}" >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "${tmp}"; if [ "${apply}" = "1" ]; then helm uninstall "${release}" -n "${namespace}" >/dev/null 2>&1 || true; fi' EXIT

echo "==> helm lint with NiceOS nginx-exporter metrics image"
helm lint "${chart_dir}" \
  --set global.security.allowInsecureImages=true \
  --set metrics.enabled=true \
  --set metrics.image.registry="${registry}" \
  --set metrics.image.repository="${repository}" \
  --set metrics.image.tag="${tag}"

echo "==> helm template with metrics enabled"
helm template "${release}" "${chart_dir}" \
  --namespace "${namespace}" \
  --set global.security.allowInsecureImages=true \
  --set metrics.enabled=true \
  --set metrics.image.registry="${registry}" \
  --set metrics.image.repository="${repository}" \
  --set metrics.image.tag="${tag}" \
  >"${tmp}"

grep -q "metrics" "${tmp}"
grep -q "${repository}" "${tmp}"
grep -q "${tag}" "${tmp}"
grep -Eq "exporter|nginx-prometheus-exporter" "${tmp}"

if [ "${apply}" = "1" ]; then
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl is required when NICEOS_HELM_APPLY=1" >&2
    exit 1
  fi

  echo "==> helm install into current cluster"
  helm install "${release}" "${chart_dir}" \
    --namespace "${namespace}" \
    --set global.security.allowInsecureImages=true \
    --set metrics.enabled=true \
    --set metrics.image.registry="${registry}" \
    --set metrics.image.repository="${repository}" \
    --set metrics.image.tag="${tag}"

  kubectl rollout status "deploy/${release}" -n "${namespace}" --timeout=180s
fi

echo "OK: helm metrics smoke test passed"
