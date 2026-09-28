#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROLE_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/versions.env"

for value in MINIO_COMMIT MC_COMMIT; do
  commit="${!value}"
  if [[ ! "${commit}" =~ ^[0-9a-f]{40}$ ]]; then
    printf 'ERROR: %s must be a verified 40-character Git commit, got: %s\n' "${value}" "${commit}" >&2
    exit 1
  fi
done

build_one() {
  local name="$1" repo="$2" commit="$3" arch="$4" release="$5"
  local image="anro-minio-build-${name}-${arch}"
  local cid
  docker build \
    --build-arg "GO_IMAGE=${GO_IMAGE}" \
    --build-arg "SOURCE_REPOSITORY=${repo}" \
    --build-arg "SOURCE_COMMIT=${commit}" \
    --build-arg "TARGETARCH=${arch}" \
    --build-arg "SOURCE_RELEASE=${release}" \
    --tag "${image}" \
    "${SCRIPT_DIR}"
  cid="$(docker create "${image}")"
  trap 'docker rm -f "${cid}" >/dev/null 2>&1 || true' RETURN
  mkdir -p "${ROLE_DIR}/files/bin/${arch}"
  docker cp "${cid}:/out/binary" "${ROLE_DIR}/files/bin/${arch}/${name}"
  chmod 0755 "${ROLE_DIR}/files/bin/${arch}/${name}"
  docker rm "${cid}" >/dev/null
  trap - RETURN
}

#for arch in amd64 arm64; do
for arch in amd64; do
  build_one minio "${MINIO_REPOSITORY}" "${MINIO_COMMIT}" "${arch}" "${MINIO_RELEASE}"
  build_one mc "${MC_REPOSITORY}" "${MC_COMMIT}" "${arch}" "${MC_RELEASE}"
done

python3 "${SCRIPT_DIR}/write_checksums.py" "${ROLE_DIR}"
printf 'Source-built binaries and checksum manifest generated successfully.\n'
