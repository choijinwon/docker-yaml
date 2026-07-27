set -euo pipefail

# Submit a CPU application image build.
# Required: GIT_URL
# Optional examples: GIT_REVISION, IMAGE_NAME, IMAGE_TAG, ENTRYPOINT_VALUE

NAMESPACE="${NAMESPACE:-argo}"
DRY_RUN="${DRY_RUN:-false}"

: "${GIT_URL:?Set GIT_URL, for example ssh://git@bitbucket.local/project/app.git}"

GIT_REVISION="${GIT_REVISION:-main}"
CONTEXT_PATH="${CONTEXT_PATH:-.}"
REQUIREMENTS_LOCK_PATH="${REQUIREMENTS_LOCK_PATH:-requirements.lock}"
GOLDEN_IMAGE_UUID="${GOLDEN_IMAGE_UUID:-py311-cpu-ubuntu2204-20260727}"
NEXUS_PYPI_URL="${NEXUS_PYPI_URL:-https://nexus.CHANGE_ME.internal/repository/pypi-group/simple}"
REGISTRY_ADDRESS="${REGISTRY_ADDRESS:-harbor.CHANGE_ME.internal}"
REGISTRY_PROJECT="${REGISTRY_PROJECT:-applications}"
CACHE_REGISTRY_ADDRESS="${CACHE_REGISTRY_ADDRESS:-harbor.CHANGE_ME.internal/build-cache}"
BUILDKIT_ADDRESS="${BUILDKIT_ADDRESS:-tcp://buildkitd.buildkit.svc.cluster.local:1234}"
IMAGE_NAME="${IMAGE_NAME:-sample-app-cpu}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
SHELL_TYPE="${SHELL_TYPE:-bash}"
ENTRYPOINT_TYPE="${ENTRYPOINT_TYPE:-module}"
ENTRYPOINT_VALUE="${ENTRYPOINT_VALUE:-src.api}"
ENTRYPOINT_ARGS="${ENTRYPOINT_ARGS:-}"
WORKING_DIRECTORY="${WORKING_DIRECTORY:-/app}"
RUN_AS_USER="${RUN_AS_USER:-10001}"
ENVIRONMENT_PROFILE="${ENVIRONMENT_PROFILE:-production}"

tmp_file=$(mktemp)
trap 'rm -f "${tmp_file}"' EXIT

cat > "${tmp_file}" <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: image-build-cpu-
  namespace: ${NAMESPACE}
spec:
  workflowTemplateRef:
    name: user-image-build-6-layer
  arguments:
    parameters:
      - name: image-type
        value: user
      - name: bitbucket-address-user-code
        value: ${GIT_URL}
      - name: git-revision
        value: ${GIT_REVISION}
      - name: context-path
        value: "${CONTEXT_PATH}"
      - name: requirements-lock-path
        value: ${REQUIREMENTS_LOCK_PATH}
      - name: golden-image-uuid
        value: ${GOLDEN_IMAGE_UUID}
      - name: nexus-pypi-url
        value: ${NEXUS_PYPI_URL}
      - name: registry-address
        value: ${REGISTRY_ADDRESS}
      - name: registry-project
        value: ${REGISTRY_PROJECT}
      - name: cache-registry-address
        value: ${CACHE_REGISTRY_ADDRESS}
      - name: buildkit-address
        value: ${BUILDKIT_ADDRESS}
      - name: image-name
        value: ${IMAGE_NAME}
      - name: image-tag
        value: ${IMAGE_TAG}
      - name: shell-type
        value: ${SHELL_TYPE}
      - name: entrypoint-type
        value: ${ENTRYPOINT_TYPE}
      - name: entrypoint-value
        value: ${ENTRYPOINT_VALUE}
      - name: entrypoint-args
        value: "${ENTRYPOINT_ARGS}"
      - name: working-directory
        value: ${WORKING_DIRECTORY}
      - name: run-as-user
        value: "${RUN_AS_USER}"
      - name: environment-profile
        value: ${ENVIRONMENT_PROFILE}
EOF

if [ "${DRY_RUN}" = "true" ]; then
  cat "${tmp_file}"
else
  kubectl create -n "${NAMESPACE}" -f "${tmp_file}"
fi
