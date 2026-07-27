set -euo pipefail

# Build the prepared Docker context through the remote BuildKit daemon and push
# the final image to Harbor. The image digest is saved for the workflow report.

: "${REPOSITORY_NAME:?REPOSITORY_NAME is required}"
: "${BUILDKIT_ADDRESS:?BUILDKIT_ADDRESS is required}"
: "${REGISTRY_ADDRESS:?REGISTRY_ADDRESS is required}"
: "${REGISTRY_PROJECT:?REGISTRY_PROJECT is required}"
: "${CACHE_REGISTRY_ADDRESS:?CACHE_REGISTRY_ADDRESS is required}"
: "${IMAGE_TAG:?IMAGE_TAG is required}"
: "${NEXUS_PYPI_URL:?NEXUS_PYPI_URL is required}"

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
IMAGE_NAME="${IMAGE_NAME:-}"
APT_MIRROR_URL="${APT_MIRROR_URL:-}"

# If the caller does not provide image-name, use the Git repository name.
if [ -z "${IMAGE_NAME}" ]; then
  IMAGE_NAME="${REPOSITORY_NAME}"
fi

IMAGE_REFERENCE="${REGISTRY_ADDRESS}/${REGISTRY_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"
CACHE_REFERENCE="${CACHE_REGISTRY_ADDRESS}/${IMAGE_NAME}:cache"

# buildctl reads the daemon address from BUILDKIT_HOST.
export BUILDKIT_HOST="${BUILDKIT_ADDRESS}"

# Import/export cache keeps rebuilds fast when requirements.lock or source did not change.
buildctl build \
  --frontend dockerfile.v0 \
  --local context="${WORKSPACE_DIR}/build-context" \
  --local dockerfile="${WORKSPACE_DIR}/build-context" \
  --opt build-arg:NEXUS_PYPI_URL="${NEXUS_PYPI_URL}" \
  --opt build-arg:APT_MIRROR_URL="${APT_MIRROR_URL}" \
  --import-cache "type=registry,ref=${CACHE_REFERENCE}" \
  --export-cache "type=registry,ref=${CACHE_REFERENCE},mode=max" \
  --output "type=image,name=${IMAGE_REFERENCE},push=true" \
  --metadata-file /tmp/build-metadata.json

# BuildKit writes the pushed image digest into metadata. Validate it before passing on.
IMAGE_DIGEST=$(jq -r '."containerimage.digest" // empty' /tmp/build-metadata.json)
echo "${IMAGE_DIGEST}" | grep -Eq '^sha256:[0-9a-f]{64}$'

# Argo reads these files as output parameters.
printf '%s' "${IMAGE_REFERENCE}" > /tmp/image-reference.txt
printf '%s' "${IMAGE_DIGEST}" > /tmp/image-digest.txt
