set -euo pipefail

# Generate the 6-layer Dockerfile for an admin-managed Golden Image.
# This workflow creates the approved base runtime image used later by user builds.

: "${IMAGE_TYPE:?IMAGE_TYPE is required}"
: "${BASE_IMAGE:?BASE_IMAGE is required}"
: "${GOLDEN_IMAGE_UUID:?GOLDEN_IMAGE_UUID is required}"
: "${PYTHON_VERSION:?PYTHON_VERSION is required}"
: "${OS_FAMILY:?OS_FAMILY is required}"
: "${OS_VERSION:?OS_VERSION is required}"
: "${ARCHITECTURE:?ARCHITECTURE is required}"
: "${ACCELERATOR:?ACCELERATOR is required}"
: "${WORKING_DIRECTORY:?WORKING_DIRECTORY is required}"
: "${RUN_AS_USER:?RUN_AS_USER is required}"
: "${ENVIRONMENT_PROFILE:?ENVIRONMENT_PROFILE is required}"

if [ "${IMAGE_TYPE}" != "golden" ]; then
  echo "golden Dockerfile requires IMAGE_TYPE=golden" >&2
  exit 1
fi

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
BUILD_CONTEXT="${WORKSPACE_DIR}/build-context"
GPU_MODEL="${GPU_MODEL:-}"
GPU_ARCHITECTURE="${GPU_ARCHITECTURE:-}"
CUDA_VERSION="${CUDA_VERSION:-}"
CUDNN_VERSION="${CUDNN_VERSION:-}"
NCCL_VERSION="${NCCL_VERSION:-}"
MINIMUM_DRIVER_VERSION="${MINIMUM_DRIVER_VERSION:-}"
NVIDIA_DRIVER_CAPABILITIES="${NVIDIA_DRIVER_CAPABILITIES:-compute,utility}"
APT_MIRROR_URL="${APT_MIRROR_URL:-}"
NEXUS_PYPI_URL="${NEXUS_PYPI_URL:-}"
COMMON_OS_PACKAGES="${COMMON_OS_PACKAGES:-ca-certificates bash curl git python3 python3-pip python3-venv}"

rm -rf "${BUILD_CONTEXT}"
mkdir -p "${BUILD_CONTEXT}"

# Store a small metadata file in the build context so Golden Image contents can be audited.
cat > "${BUILD_CONTEXT}/golden-image-metadata.json" <<EOF
{
  "imageType": "${IMAGE_TYPE}",
  "goldenImageUuid": "${GOLDEN_IMAGE_UUID}",
  "pythonVersion": "${PYTHON_VERSION}",
  "osFamily": "${OS_FAMILY}",
  "osVersion": "${OS_VERSION}",
  "architecture": "${ARCHITECTURE}",
  "accelerator": "${ACCELERATOR}",
  "gpuModel": "${GPU_MODEL}",
  "gpuArchitecture": "${GPU_ARCHITECTURE}",
  "cudaVersion": "${CUDA_VERSION}",
  "cudnnVersion": "${CUDNN_VERSION}",
  "ncclVersion": "${NCCL_VERSION}",
  "minimumDriverVersion": "${MINIMUM_DRIVER_VERSION}"
}
EOF

# The generated Dockerfile intentionally has only 6 conceptual layers:
# 1 base, 2 OS/CA policy, 3 Python tools, 4 GPU runtime metadata, 5 runtime user, 6 labels.
cat > "${BUILD_CONTEXT}/Dockerfile" <<EOF
# 1. Base Image Layer: immutable upstream/internal base image.
#    B300 must start from a Blackwell-capable CUDA base, not plain Ubuntu.
FROM ${BASE_IMAGE}

# 2. OS / CA Policy Layer: install shared runtime tools from the internal mirror.
ARG APT_MIRROR_URL
RUN if [ -n "\${APT_MIRROR_URL}" ]; then \
      sed -i "s#http://archive.ubuntu.com/ubuntu#\${APT_MIRROR_URL}#g" /etc/apt/sources.list || true; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends ${COMMON_OS_PACKAGES}; \
    rm -rf /var/lib/apt/lists/*

# 3. Python Tool Layer: prepare pip tooling through the internal PyPI endpoint.
ARG NEXUS_PYPI_URL
RUN python3 -m pip install --index-url "\${NEXUS_PYPI_URL}" --upgrade pip setuptools wheel

# 4. Runtime Metadata Layer: record CPU/GPU compatibility contract.
ENV IMAGE_TYPE=${IMAGE_TYPE}
ENV GOLDEN_IMAGE_UUID=${GOLDEN_IMAGE_UUID}
ENV PYTHON_VERSION=${PYTHON_VERSION}
ENV OS_FAMILY=${OS_FAMILY}
ENV OS_VERSION=${OS_VERSION}
ENV ARCHITECTURE=${ARCHITECTURE}
ENV ACCELERATOR=${ACCELERATOR}
ENV GPU_MODEL=${GPU_MODEL}
ENV GPU_ARCHITECTURE=${GPU_ARCHITECTURE}
ENV CUDA_VERSION=${CUDA_VERSION}
ENV CUDNN_VERSION=${CUDNN_VERSION}
ENV NCCL_VERSION=${NCCL_VERSION}
ENV MINIMUM_NVIDIA_DRIVER_VERSION=${MINIMUM_DRIVER_VERSION}
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES}
COPY golden-image-metadata.json /etc/golden-image-metadata.json

# 5. Runtime User Layer: create the common runtime directory and non-root UID.
WORKDIR ${WORKING_DIRECTORY}
RUN mkdir -p ${WORKING_DIRECTORY}; \
    if ! id -u ${RUN_AS_USER} >/dev/null 2>&1; then \
      useradd --uid ${RUN_AS_USER} --create-home --shell /bin/bash appuser; \
    fi; \
    chown -R ${RUN_AS_USER}:0 ${WORKING_DIRECTORY}

# 6. Golden Image Contract Layer: labels and default command.
ENV ENVIRONMENT_PROFILE=${ENVIRONMENT_PROFILE}
LABEL image.type="${IMAGE_TYPE}"
LABEL golden.image.uuid="${GOLDEN_IMAGE_UUID}"
LABEL accelerator="${ACCELERATOR}"
LABEL gpu.model="${GPU_MODEL}"
USER ${RUN_AS_USER}
CMD ["python3", "--version"]
EOF

printf '%s' "${BASE_IMAGE#*@}" > /tmp/parent-image-digest.txt
