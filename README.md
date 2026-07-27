# Python Image Builder

폐쇄망 환경에서 CPU 또는 여러 GPU 타입 기반 Python 애플리케이션 컨테이너 이미지를 빌드하기 위한 최소 Argo Workflow 구조입니다.

## 핵심 원칙

- CPU와 GPU 타입을 같은 Workflow에서 Golden Image UUID로 선택합니다.
- Golden Image는 실제 빌드 시 Harbor `repository@sha256:digest`를 사용합니다.
- 사용자는 승인된 Golden Image UUID, Git 소스, `requirements.lock`, 실행 Shell/Entrypoint만 입력합니다.
- MLflow, PyTorch, NumPy 등 애플리케이션 패키지는 Golden Image가 아니라 `requirements.lock`에서 관리합니다.
- GPU 이미지는 일반 Ubuntu Base Image가 아니라 GPU 아키텍처에 맞는 CUDA Golden Image를 사용합니다.
- B300은 현재 등록된 GPU 예시이며, 다른 GPU도 Catalog Record 추가로 확장합니다.
- 현재 프로젝트는 Application Image Builder만 포함합니다.

## 문서

- [파라미터 표준](docs/parameter-standard.md)
- [Golden Image Catalog](docs/golden-image-catalog.md)
- [B300 CUDA 공식 기준 요약 이미지](docs/nvidia-b300-cuda-reference.svg)
- [6단계 Docker Layer Image Build Workflow](workflows/python-image-build-6-layer.yaml)
- [운영형 Workflow 개선 포인트](docs/operational-workflow-improvement.md)

## 필요한 구조

```text
docker-yaml/
├── README.md
├── kustomization.yaml
├── docs/
│   ├── golden-image-catalog.md
│   ├── nvidia-b300-cuda-reference.svg
│   ├── operational-workflow-improvement.md
│   ├── parameter-standard.md
├── manifests/
│   ├── golden-image-catalog.configmap.yaml
│   ├── run-b300.workflow.yaml
│   └── run-cpu.workflow.yaml
├── scripts/
│   ├── user/
│   │   ├── submit_b300_build.sh
│   │   └── submit_cpu_build.sh
│   └── image-builder/
│       ├── build_and_push_image.sh
│       ├── create_6_layer_dockerfile.sh
│       ├── fetch_source.sh
│       ├── resolve_golden_image.py
│       ├── validate_input.py
│       └── write_result.sh
└── workflows/
    └── python-image-build-6-layer.yaml
```

## 사용 흐름

1. `manifests/golden-image-catalog.configmap.yaml`에 CPU/GPU Golden Image Digest를 등록합니다.
2. `kubectl apply -k .`로 Catalog와 스크립트 ConfigMap을 생성합니다.
3. `workflows/python-image-build-6-layer.yaml`를 등록합니다.
4. CPU 또는 GPU 실행 manifest를 제출합니다.

```text
kubectl apply -k .
kubectl apply -f workflows/python-image-build-6-layer.yaml
kubectl create -f manifests/run-cpu.workflow.yaml
kubectl create -f manifests/run-b300.workflow.yaml
```

`manifests/run-cpu.workflow.yaml`와 `manifests/run-b300.workflow.yaml`는 사용자 제출 예시입니다. 다른 GPU는 Catalog에 Golden Image Record를 추가하고, 실행 manifest에서 `golden-image-uuid`, `accelerator`, `gpu-model`, `gpu-architecture`, `cuda-version`, `minimum-driver-version`만 맞추면 됩니다.

사용자는 스크립트로 제출할 수도 있습니다.

```text
GIT_URL=ssh://git@bitbucket.local/project/app.git \
IMAGE_NAME=my-app-cpu \
scripts/user/submit_cpu_build.sh

GIT_URL=ssh://git@bitbucket.local/project/app.git \
IMAGE_NAME=my-app-b300 \
scripts/user/submit_b300_build.sh
```

제출 전에 생성될 Workflow YAML만 확인하려면 `DRY_RUN=true`를 사용합니다.

```text
DRY_RUN=true \
GIT_URL=ssh://git@bitbucket.local/project/app.git \
scripts/user/submit_cpu_build.sh
```

## 설명용 요약

이 프로젝트는 CPU와 여러 GPU 타입을 Golden Image Catalog로 추상화해서, 하나의 Argo Workflow로 Python Application Image를 재현 가능하게 빌드하는 구조입니다. 사용자는 Base Image를 직접 선택하지 않고 Golden Image UUID만 입력합니다. Workflow는 Catalog에서 UUID를 조회해 CPU, B300, 또는 다른 GPU 타입에 맞는 `repository@digest` 이미지를 선택하고, Git 소스와 `requirements.lock`을 기준으로 Application Image를 빌드합니다.

GPU가 추가될 때 Workflow를 새로 만들 필요는 없습니다. Golden Image Catalog에 GPU별 UUID, CUDA/cuDNN/NCCL, Driver 기준, Harbor Digest를 추가하면 같은 Workflow에서 선택해 사용할 수 있습니다.
