#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  echo "usage: $0 <new-go-version> [niceos-stream] [image-revision]" >&2
  echo "example: $0 1.26.5 13 1" >&2
  exit 2
fi

NEW_VERSION="$1"
NICEOS_STREAM="${2:-13}"
IMAGE_REVISION="${3:-1}"
NEW_TAG="${NEW_VERSION}-niceos${NICEOS_STREAM}-r${IMAGE_REVISION}"
OLD_VERSION_REGEX='1\.26\.[0-9]+'

files=(
  README.md
  Makefile
  scripts/build.sh
  scripts/test.sh
  scripts/publish.sh
  compat/contract.yaml
  releases/1.26.4-niceos13-r1.yaml
  docs/releases/1.26.4-niceos13-r1.md
  .niceos-source.yaml
  catalog.fragment.yaml
)

for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  sed -i -E \
    -e "s/${OLD_VERSION_REGEX}/${NEW_VERSION}/g" \
    -e "s/1\.26\.[0-9]+-niceos[0-9]+-r[0-9]+/${NEW_TAG}/g" \
    -e "s/niceos[0-9]+-r[0-9]+/niceos${NICEOS_STREAM}-r${IMAGE_REVISION}/g" \
    "$f"
done

old_release="releases/1.26.4-niceos13-r1.yaml"
new_release="releases/${NEW_TAG}.yaml"
if [[ -f "${old_release}" && "${old_release}" != "${new_release}" ]]; then
  cp "${old_release}" "${new_release}"
fi

old_doc="docs/releases/1.26.4-niceos13-r1.md"
new_doc="docs/releases/${NEW_TAG}.md"
if [[ -f "${old_doc}" && "${old_doc}" != "${new_doc}" ]]; then
  cp "${old_doc}" "${new_doc}"
fi

printf 'Updated Golang image version to %s\n' "${NEW_TAG}"
printf 'Review release notes, build, test, push, then tag source as v%s\n' "${NEW_TAG}"
