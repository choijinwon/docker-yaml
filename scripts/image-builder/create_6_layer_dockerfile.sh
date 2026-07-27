set -euo pipefail

: "${RUNTIME_IMAGE:?RUNTIME_IMAGE is required}"
: "${CONTEXT_PATH:?CONTEXT_PATH is required}"
: "${REQUIREMENTS_LOCK_PATH:?REQUIREMENTS_LOCK_PATH is required}"
: "${SHELL_TYPE:?SHELL_TYPE is required}"
: "${ENTRYPOINT_TYPE:?ENTRYPOINT_TYPE is required}"
: "${ENTRYPOINT_VALUE:?ENTRYPOINT_VALUE is required}"
: "${WORKING_DIRECTORY:?WORKING_DIRECTORY is required}"
: "${RUN_AS_USER:?RUN_AS_USER is required}"
: "${ENVIRONMENT_PROFILE:?ENVIRONMENT_PROFILE is required}"

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
SOURCE_DIR="${WORKSPACE_DIR}/source/${CONTEXT_PATH}"
BUILD_CONTEXT="${WORKSPACE_DIR}/build-context"
LOCK_FILE="${SOURCE_DIR}/${REQUIREMENTS_LOCK_PATH}"

if [ ! -f "${LOCK_FILE}" ]; then
  echo "requirements lock file is required: ${LOCK_FILE}" >&2
  exit 1
fi

if grep -Ev '^[[:space:]]*($|#|[A-Za-z0-9_.-]+==[^=<>!~ ]+)$' "${LOCK_FILE}"; then
  echo "requirements.lock must pin exact versions only" >&2
  exit 1
fi

rm -rf "${BUILD_CONTEXT}"
mkdir -p "${BUILD_CONTEXT}"
cp -R "${SOURCE_DIR}/." "${BUILD_CONTEXT}/"
cp "${LOCK_FILE}" "${BUILD_CONTEXT}/requirements.lock"

sha256sum "${LOCK_FILE}" | awk '{print $1}' > /tmp/lock-hash.txt

ENTRYPOINT_ARGS="${ENTRYPOINT_ARGS:-}"
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

cat > "${BUILD_CONTEXT}/Dockerfile" <<EOF
# 1. Golden Image Layer: Python / OS / CUDA / CA policy comes from approved base digest
FROM ${RUNTIME_IMAGE}

# 2. Runtime Policy Layer: working directory, Python, pip, and environment policy
WORKDIR ${WORKING_DIRECTORY}
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV ENVIRONMENT_PROFILE=${ENVIRONMENT_PROFILE}

# 3. Dependency Lock Layer: copy only requirements.lock first for cache reuse
COPY requirements.lock ${WORKING_DIRECTORY}/requirements.lock

# 4. Python Package Layer: install pinned packages from Nexus/internal PyPI
ARG NEXUS_PYPI_URL
RUN python -m pip install --index-url "\${NEXUS_PYPI_URL}" --only-binary=:all: --requirement ${WORKING_DIRECTORY}/requirements.lock

# 5. Application Source Layer: copy user source after dependency install
COPY . ${WORKING_DIRECTORY}

# 6. Execution Config Layer: apply user-provided shell and entrypoint
USER ${RUN_AS_USER}
CMD ["${SHELL_TYPE}", "-lc", "${START_COMMAND}"]
EOF
