set -euo pipefail

# Build the Docker context and generate the User Image 5-layer Dockerfile.
# This is where the image diagram becomes an actual Docker layer policy.

: "${RUNTIME_IMAGE:?RUNTIME_IMAGE is required}"
: "${IMAGE_TYPE:?IMAGE_TYPE is required}"
: "${CONTEXT_PATH:?CONTEXT_PATH is required}"
: "${REQUIREMENTS_LOCK_PATH:?REQUIREMENTS_LOCK_PATH is required}"
: "${ACCELERATOR:?ACCELERATOR is required}"
: "${SHELL_TYPE:?SHELL_TYPE is required}"
: "${ENTRYPOINT_TYPE:?ENTRYPOINT_TYPE is required}"
: "${ENTRYPOINT_VALUE:?ENTRYPOINT_VALUE is required}"
: "${WORKING_DIRECTORY:?WORKING_DIRECTORY is required}"
: "${RUN_AS_USER:?RUN_AS_USER is required}"
: "${ENVIRONMENT_PROFILE:?ENVIRONMENT_PROFILE is required}"

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
GPU_MODEL="${GPU_MODEL:-}"
GPU_ARCHITECTURE="${GPU_ARCHITECTURE:-}"
ARCHITECTURE="${ARCHITECTURE:-}"
CUDA_VERSION="${CUDA_VERSION:-}"
MINIMUM_DRIVER_VERSION="${MINIMUM_DRIVER_VERSION:-}"
NVIDIA_DRIVER_CAPABILITIES="${NVIDIA_DRIVER_CAPABILITIES:-compute,utility}"
SOURCE_DIR="${WORKSPACE_DIR}/source/${CONTEXT_PATH}"
BUILD_CONTEXT="${WORKSPACE_DIR}/build-context"
LOCK_FILE="${SOURCE_DIR}/${REQUIREMENTS_LOCK_PATH}"

if [ "${IMAGE_TYPE}" != "user" ]; then
  echo "user image Dockerfile requires IMAGE_TYPE=user" >&2
  exit 1
fi

# requirements.lock is mandatory because package versions must be reproducible.
if [ ! -f "${LOCK_FILE}" ]; then
  echo "requirements lock file is required: ${LOCK_FILE}" >&2
  exit 1
fi

# Keep the lock file simple: comments, blanks, and exact pins like package==1.2.3.
if grep -Ev '^[[:space:]]*($|#|[A-Za-z0-9_.-]+==[^=<>!~ ]+)$' "${LOCK_FILE}"; then
  echo "requirements.lock must pin exact versions only" >&2
  exit 1
fi

# Rebuild the context from the selected source path only.
rm -rf "${BUILD_CONTEXT}"
mkdir -p "${BUILD_CONTEXT}"
cp -R "${SOURCE_DIR}/." "${BUILD_CONTEXT}/"

# Normalize the lock file name so the generated Dockerfile can always use
# /requirements.lock even when the user provided a nested lock file path.
cp "${LOCK_FILE}" "${BUILD_CONTEXT}/requirements.lock"

# Store the lock hash in the workflow result for audit and rebuild tracking.
sha256sum "${LOCK_FILE}" | awk '{print $1}' > /tmp/lock-hash.txt

ENTRYPOINT_ARGS="${ENTRYPOINT_ARGS:-}"

# Convert the user's entrypoint choice into one shell command used by Docker CMD.
case "${ENTRYPOINT_TYPE}" in
  module)
    START_COMMAND="python -m ${ENTRYPOINT_VALUE} ${ENTRYPOINT_ARGS}"
    ;;
  script)
    START_COMMAND="python ${ENTRYPOINT_VALUE} ${ENTRYPOINT_ARGS}"
    ;;
  binary)
    START_COMMAND="${ENTRYPOINT_VALUE} ${ENTRYPOINT_ARGS}"
    ;;
  shell)
    START_COMMAND="${SHELL_TYPE} ${ENTRYPOINT_VALUE} ${ENTRYPOINT_ARGS}"
    ;;
  *)
    echo "Unsupported entrypoint-type: ${ENTRYPOINT_TYPE}" >&2
    exit 1
    ;;
esac

# The generated Dockerfile treats Golden Image as the approved base and adds
# 5 user-image layers: runtime policy, lock copy, package install, source copy, run config.
cat > "${BUILD_CONTEXT}/Dockerfile" <<EOF
# Base. Golden Image: Python / OS / CUDA / CA policy comes from approved base digest.
#    For B300, this must be a Blackwell-capable CUDA image, not a plain Ubuntu image.
FROM ${RUNTIME_IMAGE}

# 1. Runtime Policy Layer: working directory, Python, pip, GPU, and environment policy
WORKDIR ${WORKING_DIRECTORY}
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV ENVIRONMENT_PROFILE=${ENVIRONMENT_PROFILE}
ENV IMAGE_TYPE=${IMAGE_TYPE}
ENV ARCHITECTURE=${ARCHITECTURE}
ENV ACCELERATOR=${ACCELERATOR}
ENV GPU_MODEL=${GPU_MODEL}
ENV GPU_ARCHITECTURE=${GPU_ARCHITECTURE}
ENV CUDA_VERSION=${CUDA_VERSION}
ENV MINIMUM_NVIDIA_DRIVER_VERSION=${MINIMUM_DRIVER_VERSION}
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES}

# 2. Dependency Lock Layer: copy only requirements.lock first for cache reuse
COPY requirements.lock ${WORKING_DIRECTORY}/requirements.lock

# 3. Python Package Layer: install pinned packages from Nexus/internal PyPI
ARG NEXUS_PYPI_URL
RUN python -m pip install --index-url "\${NEXUS_PYPI_URL}" --only-binary=:all: --requirement ${WORKING_DIRECTORY}/requirements.lock

# 4. Application Source Layer: copy user source after dependency install
COPY . ${WORKING_DIRECTORY}

# 5. Execution Config Layer: apply user-provided shell and entrypoint
USER ${RUN_AS_USER}
CMD ["${SHELL_TYPE}", "-lc", "${START_COMMAND}"]
EOF
