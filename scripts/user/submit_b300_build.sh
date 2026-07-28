set -euo pipefail

# Backward-compatible B300 shortcut.
# New GPU models should use submit_gpu_build.sh with a GPU-specific GOLDEN_IMAGE_UUID.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

export GPU_PROFILE="${GPU_PROFILE:-b300}"
export GOLDEN_IMAGE_UUID="${GOLDEN_IMAGE_UUID:-py311-cuda128-b300-ubuntu2204-20260727}"
export IMAGE_NAME="${IMAGE_NAME:-sample-app-b300}"

exec "${SCRIPT_DIR}/submit_gpu_build.sh"
