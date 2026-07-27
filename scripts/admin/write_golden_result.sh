set -euo pipefail

# Create the final Golden Image build report artifact.
# This report is used to register or review the Catalog record after the image is pushed.

: "${IMAGE_TYPE:?IMAGE_TYPE is required}"
: "${GOLDEN_IMAGE_UUID:?GOLDEN_IMAGE_UUID is required}"
: "${BASE_IMAGE:?BASE_IMAGE is required}"
: "${PYTHON_VERSION:?PYTHON_VERSION is required}"
: "${OS_FAMILY:?OS_FAMILY is required}"
: "${OS_VERSION:?OS_VERSION is required}"
: "${ARCHITECTURE:?ARCHITECTURE is required}"
: "${ACCELERATOR:?ACCELERATOR is required}"
: "${IMAGE_REFERENCE:?IMAGE_REFERENCE is required}"
: "${IMAGE_DIGEST:?IMAGE_DIGEST is required}"

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
OUTPUT_DIR="${WORKSPACE_DIR}/output"
mkdir -p "${OUTPUT_DIR}"

# Argo stores this file as the golden-build-report artifact.
cat > "${OUTPUT_DIR}/golden-build-report.json" <<EOF
{
  "workflowName": "${WORKFLOW_NAME:-}",
  "workflowUid": "${WORKFLOW_UID:-}",
  "namespace": "${WORKFLOW_NAMESPACE:-}",
  "imageType": "${IMAGE_TYPE}",
  "goldenImageUuid": "${GOLDEN_IMAGE_UUID}",
  "baseImage": "${BASE_IMAGE}",
  "pythonVersion": "${PYTHON_VERSION}",
  "osFamily": "${OS_FAMILY}",
  "osVersion": "${OS_VERSION}",
  "architecture": "${ARCHITECTURE}",
  "accelerator": "${ACCELERATOR}",
  "gpuModel": "${GPU_MODEL:-}",
  "gpuArchitecture": "${GPU_ARCHITECTURE:-}",
  "cudaVersion": "${CUDA_VERSION:-}",
  "cudnnVersion": "${CUDNN_VERSION:-}",
  "ncclVersion": "${NCCL_VERSION:-}",
  "minimumDriverVersion": "${MINIMUM_DRIVER_VERSION:-}",
  "imageReference": "${IMAGE_REFERENCE}",
  "imageDigest": "${IMAGE_DIGEST}",
  "catalogRecordCandidate": {
    "uuid": "${GOLDEN_IMAGE_UUID}",
    "status": "active",
    "imageReference": "${IMAGE_REFERENCE}",
    "digest": "${IMAGE_DIGEST}"
  },
  "dockerLayerPolicy": [
    "1-base-image",
    "2-os-ca-policy",
    "3-runtime-tooling",
    "4-runtime-metadata",
    "5-runtime-user",
    "6-golden-image-contract"
  ],
  "status": "SUCCEEDED",
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
EOF

cat "${OUTPUT_DIR}/golden-build-report.json"
