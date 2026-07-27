set -euo pipefail

: "${REPOSITORY_URL:?REPOSITORY_URL is required}"
: "${GIT_REVISION:?GIT_REVISION is required}"

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
SOURCE_DIR="${WORKSPACE_DIR}/source"

rm -rf "${SOURCE_DIR}"
if git clone --depth 1 --branch "${GIT_REVISION}" "${REPOSITORY_URL}" "${SOURCE_DIR}"; then
  exit 0
fi

rm -rf "${SOURCE_DIR}"
git clone --depth 1 "${REPOSITORY_URL}" "${SOURCE_DIR}"
cd "${SOURCE_DIR}"
git fetch --depth 1 origin "${GIT_REVISION}"
git checkout FETCH_HEAD
