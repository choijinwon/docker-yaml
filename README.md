# Python Image Builder

폐쇄망 환경에서 Python Golden Image와 User Application Image를 분리해 빌드하기 위한 최소 Argo Workflow 구조입니다.

## 핵심 원칙

- Workflow YAML은 이미지 타입 기준으로 `golden`, `user` 두 개로 분리합니다.
- Golden Image Workflow는 운영자가 CPU/GPU 기준 이미지를 만들고 Harbor에 Push할 때 사용합니다.
- User Image Workflow는 사용자가 Golden Image UUID를 선택해 애플리케이션 이미지를 만들 때 사용합니다.
- Golden Image는 실제 빌드 시 Harbor `repository@sha256:digest`를 사용합니다.
- 사용자는 승인된 Golden Image UUID, Git 소스, `requirements.lock`, 실행 Shell/Entrypoint만 입력합니다.
- MLflow, PyTorch, NumPy 등 애플리케이션 패키지는 Golden Image가 아니라 `requirements.lock`에서 관리합니다.
- GPU 이미지는 일반 Ubuntu Base Image가 아니라 GPU 아키텍처에 맞는 CUDA Golden Image를 사용합니다.
- B300은 현재 등록된 GPU 예시이며, 다른 GPU도 Catalog Record 추가로 확장합니다.

## 문서

- [파라미터 표준](docs/parameter-standard.md)
- [사용자 UI 입력 가이드](docs/user-ui-guide.md)
- [Golden Image Catalog](docs/golden-image-catalog.md)
- [현업 설명 가이드](docs/explanation-guide.md)
- [B300 CUDA 공식 기준 요약 이미지](docs/nvidia-b300-cuda-reference.svg)
- [Golden Image 6단계 Workflow](workflows/golden-image-build.yaml)
- [User Image 6단계 Workflow](workflows/user-image-build.yaml)
- [운영형 Workflow 개선 포인트](docs/operational-workflow-improvement.md)

## 필요한 구조

```text
docker-yaml/
├── README.md
├── kustomization.yaml
├── docs/
│   ├── golden-image-catalog.md
│   ├── explanation-guide.md
│   ├── nvidia-b300-cuda-reference.svg
│   ├── operational-workflow-improvement.md
│   ├── parameter-standard.md
│   ├── user-ui-guide.md
├── manifests/
│   ├── golden-image-catalog.configmap.yaml
│   ├── user-image-ui-schema.configmap.yaml
│   ├── run-b300.workflow.yaml
│   └── run-cpu.workflow.yaml
├── scripts/
│   ├── user/
│   │   ├── submit_b300_build.sh
│   │   └── submit_cpu_build.sh
│   └── admin/
│       ├── build_and_push_image.sh
│       ├── create_6_layer_dockerfile.sh
│       ├── create_golden_6_layer_dockerfile.sh
│       ├── fetch_source.sh
│       ├── resolve_golden_image.py
│       ├── validate_input.py
│       ├── validate_golden_input.py
│       ├── write_golden_result.sh
│       └── write_result.sh
└── workflows/
    ├── golden-image-build.yaml
    └── user-image-build.yaml
```

## 사용 흐름

1. `kubectl apply -k .`로 Catalog와 스크립트 ConfigMap을 생성합니다.
2. `workflows/golden-image-build.yaml`를 등록합니다.
3. `workflows/user-image-build.yaml`를 등록합니다.
4. 운영자는 Golden Image Workflow로 CPU/GPU 기준 이미지를 생성합니다.
5. 생성된 Digest를 `manifests/golden-image-catalog.configmap.yaml`에 등록합니다.
6. 사용자는 User Image Workflow 실행 manifest를 제출합니다.

```text
kubectl apply -k .
kubectl apply -f workflows/golden-image-build.yaml
kubectl apply -f workflows/user-image-build.yaml
kubectl create -f manifests/run-cpu.workflow.yaml
kubectl create -f manifests/run-b300.workflow.yaml
```

`manifests/run-cpu.workflow.yaml`와 `manifests/run-b300.workflow.yaml`는 사용자 제출 예시입니다. 다른 GPU는 Catalog에 Golden Image Record를 추가하고, 사용자 실행 manifest에서는 `golden-image-uuid`만 해당 UUID로 바꾸면 됩니다.

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

이 프로젝트는 이미지 빌드를 `golden`과 `user` 두 타입으로 분리합니다. `golden` Workflow는 운영자가 CPU/B300/다른 GPU 기준 이미지를 만들고, `user` Workflow는 사용자가 승인된 Golden Image UUID와 Git 소스, `requirements.lock`을 기준으로 Application Image를 빌드합니다. 사용자는 GPU/CUDA/Driver 값을 직접 넣지 않고 Catalog에 배포된 Golden Image 정보를 상속합니다.

GPU가 추가될 때 User Workflow를 새로 만들 필요는 없습니다. Golden Image Workflow로 GPU별 기준 이미지를 만들고 Catalog에 UUID, CUDA/cuDNN/NCCL, Driver 기준, Harbor Digest를 추가하면 User Workflow에서 선택해 사용할 수 있습니다.
