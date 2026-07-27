set -euo pipefail

# Create the final build report artifact.
# This file is the small audit record that says exactly what source, base image,
# lock hash, and pushed image digest were used.

: "${REPOSITORY_NAME:?REPOSITORY_NAME is required}"
: "${IMAGE_TYPE:?IMAGE_TYPE is required}"
: "${GIT_REVISION:?GIT_REVISION is required}"
: "${CONTEXT_PATH:?CONTEXT_PATH is required}"
: "${REQUIREMENTS_LOCK_PATH:?REQUIREMENTS_LOCK_PATH is required}"
: "${ACCELERATOR:?ACCELERATOR is required}"
: "${RUNTIME_IMAGE:?RUNTIME_IMAGE is required}"
: "${LOCK_HASH:?LOCK_HASH is required}"
: "${IMAGE_REFERENCE:?IMAGE_REFERENCE is required}"
: "${IMAGE_DIGEST:?IMAGE_DIGEST is required}"

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
OUTPUT_DIR="${WORKSPACE_DIR}/output"
mkdir -p "${OUTPUT_DIR}"

# Argo stores this file as the build-report artifact.
cat > "${OUTPUT_DIR}/build-report.json" <<EOF
{
  "workflowName": "${WORKFLOW_NAME:-}",
  "workflowUid": "${WORKFLOW_UID:-}",
  "namespace": "${WORKFLOW_NAMESPACE:-}",
  "imageType": "${IMAGE_TYPE}",
  "repositoryName": "${REPOSITORY_NAME}",
  "gitRevision": "${GIT_REVISION}",
  "contextPath": "${CONTEXT_PATH}",
  "requirementsLockPath": "${REQUIREMENTS_LOCK_PATH}",
  "architecture": "${ARCHITECTURE:-}",
  "accelerator": "${ACCELERATOR}",
  "gpuModel": "${GPU_MODEL:-}",
  "gpuArchitecture": "${GPU_ARCHITECTURE:-}",
  "cudaVersion": "${CUDA_VERSION:-}",
  "minimumDriverVersion": "${MINIMUM_DRIVER_VERSION:-}",
  "runtimeImage": "${RUNTIME_IMAGE}",
  "lockHash": "${LOCK_HASH}",
  "imageReference": "${IMAGE_REFERENCE}",
  "imageDigest": "${IMAGE_DIGEST}",
  "dockerLayerPolicy": [
    "1-golden-image",
    "2-runtime-policy",
    "3-dependency-lock",
    "4-package-install",
    "5-application-source",
    "6-execution-config"
  ],
  "status": "SUCCEEDED",
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
EOF

cat "${OUTPUT_DIR}/build-report.json"
