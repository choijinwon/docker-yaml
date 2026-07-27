# Explanation Guide

이 문서는 현업 담당자에게 현재 Python Image Builder 구조를 설명할 때 사용하는 가이드입니다.

## 한 줄 요약

CPU와 여러 GPU 타입을 Golden Image Catalog로 관리하고, 하나의 Argo Workflow로 Python Application Image를 재현 가능하게 빌드하는 구조입니다.

## 왜 필요한가

기존 방식처럼 사용자가 Base Image나 패키지 설치 방식을 직접 정하면 이미지마다 환경이 달라지고, GPU/CUDA/Driver 호환성도 흔들릴 수 있습니다.

이 구조에서는 사용자가 Base Image를 직접 고르지 않습니다. 운영에서 승인한 Golden Image UUID만 선택하고, Workflow가 Catalog에서 해당 UUID를 Harbor `repository@sha256:digest`로 변환해 빌드합니다.

## 전체 흐름

```text
Golden Image Catalog
  -> CPU/GPU Golden Image UUID 선택
  -> Harbor repository@sha256:digest 조회
  -> Git 소스 Clone
  -> requirements.lock 검증
  -> 6단계 Dockerfile 생성
  -> BuildKit Build/Push
  -> build-report.json 생성
```

## 핵심 구조

```text
workflows/python-image-build-6-layer.yaml
- 실제 Argo WorkflowTemplate

manifests/golden-image-catalog.configmap.yaml
- CPU/GPU Golden Image UUID와 Digest 매핑

manifests/run-cpu.workflow.yaml
manifests/run-b300.workflow.yaml
- 사용자가 제출할 실행 예시

scripts/admin/
- Workflow Pod 안에서 실행되는 내부 빌드 스크립트

scripts/user/
- 사용자가 환경변수만 넣고 Workflow를 제출하는 편의 스크립트
```

## CPU와 GPU 처리 방식

Workflow는 CPU용, GPU용으로 나뉘지 않습니다. 하나의 Workflow를 사용하고, Golden Image UUID만 다르게 선택합니다.

CPU 예시:

```text
golden-image-uuid = py311-cpu-ubuntu2204-20260727
accelerator       = cpu
```

B300 GPU 예시:

```text
golden-image-uuid      = py311-cuda128-b300-ubuntu2204-20260727
accelerator            = cuda
gpu-model              = b300
gpu-architecture       = blackwell
cuda-version           = 12.8
minimum-driver-version = 570.26
```

다른 GPU가 추가되면 Workflow를 새로 만들지 않습니다. Catalog에 GPU별 Golden Image Record를 추가하고 실행 manifest 또는 사용자 스크립트의 GPU 값을 바꾸면 됩니다.

## 파라미터를 추가한 이유

파라미터가 늘어난 이유는 사용자가 더 많이 입력하게 하려는 목적이 아닙니다.

운영에서 이미지 빌드를 안전하게 반복하려면 다음 정보가 빌드 기록에 남아야 합니다.

```text
무엇을 기준 이미지로 썼는지
어떤 소스를 빌드했는지
어떤 패키지 버전을 설치했는지
CPU/GPU 중 어떤 실행 환경인지
GPU라면 CUDA/Driver 호환 기준이 무엇인지
컨테이너가 어떤 명령으로 실행되는지
결과 이미지를 어디에 어떤 태그로 올렸는지
```

그래서 파라미터는 크게 네 가지 목적을 가집니다.

| 목적 | 관련 파라미터 | 추가 이유 |
| --- | --- | --- |
| 기준 이미지 통제 | `golden_image_uuid`, `accelerator`, `gpu_model`, `cuda_version`, `minimum_driver_version` | 사용자가 임의 Base Image를 쓰지 않고 승인된 CPU/GPU 이미지만 쓰게 하기 위해 |
| 재현성 보장 | `git_url`, `git_revision`, `requirements_lock_path`, `context_path` | 같은 소스와 같은 패키지 버전으로 다시 빌드할 수 있게 하기 위해 |
| 실행 방식 표준화 | `shell_type`, `entrypoint_type`, `entrypoint_value`, `entrypoint_args`, `working_directory`, `run_as_user` | 컨테이너 실행 명령을 Dockerfile 안에 명확히 남기고 Shell 실행을 제한하기 위해 |
| 결과 추적 | `output_repository`, `output_tag`, `image_name`, `environment_profile` | Harbor에 올라간 이미지가 어느 서비스/환경/빌드 결과인지 추적하기 위해 |

현업 설명에서는 이렇게 말하면 됩니다.

```text
파라미터가 늘어난 것은 사용자의 입력 부담을 늘리기 위한 것이 아니라,
운영에서 반드시 관리해야 하는 기준 이미지, 소스, 패키지, 실행 명령, 결과 위치를
빌드 기록으로 남기기 위한 것입니다.
```

## B300 설명 포인트

B300은 일반 Ubuntu 이미지만으로는 운영 기준을 만족하기 어렵습니다.

이유:

- B300은 Blackwell 계열 GPU입니다.
- Blackwell은 CUDA 12.8 이상 기준으로 관리해야 합니다.
- CUDA 12.8 GA 기준 Linux NVIDIA Driver 최소 버전은 570.26입니다.
- 따라서 B300용 Golden Image는 Ubuntu 단독 이미지가 아니라 CUDA/cuDNN/NCCL이 포함된 NVIDIA CUDA 계열 이미지를 내부 Harbor에 미러링해서 사용해야 합니다.

## 6단계 Docker Layer

```text
1. Golden Image Layer
   승인된 CPU/GPU Golden Image Digest 사용

2. Runtime Policy Layer
   WORKDIR, Python/Pip, GPU Runtime 환경 설정

3. Dependency Lock Layer
   requirements.lock 먼저 복사

4. Python Package Layer
   Nexus/internal PyPI에서 고정 버전 설치

5. Application Source Layer
   사용자 소스 복사

6. Execution Config Layer
   Shell/Entrypoint/User 설정 적용
```

이 순서로 나눈 이유는 `requirements.lock`이 바뀌지 않으면 패키지 설치 레이어 캐시를 재사용하기 위해서입니다.

## 운영자 역할

운영자는 다음을 준비합니다.

```text
1. CPU/GPU Golden Image 생성
2. Harbor에 repository@digest 형태로 Push
3. golden-image-catalog.configmap.yaml에 UUID와 Digest 등록
4. python-admin-scripts ConfigMap 배포
5. python-image-build-6-layer WorkflowTemplate 등록
```

## 사용자 역할

사용자는 다음 값만 선택합니다.

```text
Git Repository
Branch 또는 Commit
Golden Image UUID
requirements.lock 경로
Image Name / Tag
Shell / Entrypoint
```

CPU 실행:

```text
GIT_URL=ssh://git@bitbucket.local/project/app.git \
IMAGE_NAME=my-app-cpu \
scripts/user/submit_cpu_build.sh
```

B300 실행:

```text
GIT_URL=ssh://git@bitbucket.local/project/app.git \
IMAGE_NAME=my-app-b300 \
scripts/user/submit_b300_build.sh
```

제출 전 확인:

```text
DRY_RUN=true \
GIT_URL=ssh://git@bitbucket.local/project/app.git \
scripts/user/submit_cpu_build.sh
```

## 설명할 때 피해야 할 오해

- 이 구조는 B300 전용이 아닙니다.
- Workflow는 GPU마다 새로 만들지 않습니다.
- 사용자는 Base Image를 직접 고르지 않습니다.
- `requirements.lock`은 선택이 아니라 재현성을 위한 필수 입력입니다.
- Golden Image Digest는 태그보다 중요합니다.

## 발표용 짧은 문장

```text
이 구조는 CPU와 GPU별 실행 환경을 Golden Image Catalog로 표준화하고,
사용자는 UUID와 소스/requirements.lock/Entrypoint만 입력해서
하나의 Argo Workflow로 재현 가능한 Python Application Image를 빌드하는 방식입니다.
```
