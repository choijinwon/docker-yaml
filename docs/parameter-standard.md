# Parameter Standard

이 문서는 CPU와 여러 GPU 타입을 같은 Application Image Workflow에서 사용하기 위한 파라미터 표준을 정의합니다.

## Golden Image Catalog 파라미터

| 이름 | 필수 | 예시 | 설명 |
| --- | --- | --- | --- |
| `golden_image_uuid` | Y | `py311-cpu-ubuntu2204-20260727` | Catalog에서 조회할 고유 ID |
| `python_version` | Y | `3.11.9` | Golden Image에 포함할 Python 버전 |
| `os_family` | Y | `ubuntu` | OS 계열 |
| `os_version` | Y | `22.04` | OS 버전 |
| `accelerator` | Y | `cpu`, `cuda` | CPU/GPU Runtime 구분 |
| `gpu_model` | N | `b300`, `h100`, `a100` | GPU 모델 |
| `gpu_architecture` | N | `blackwell`, `hopper`, `ampere` | GPU 아키텍처 |
| `cuda_version` | N | `12.8` | GPU 이미지일 때 CUDA 버전 |
| `cudnn_version` | N | `8.9` | GPU 이미지일 때 cuDNN 버전 |
| `nccl_version` | N | `2.x` | GPU 분산 학습/추론 통신 라이브러리 |
| `minimum_driver_version` | N | `570.26` | CUDA Runtime과 호환되는 최소 NVIDIA Driver |
| `base_image` | Y | `harbor.local/nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04` | 내부 Harbor에 저장된 Base Image |
| `output_repository` | Y | `harbor.local/platform/python-golden` | Golden Image 저장소 |
| `output_tag` | Y | `py311-cuda128-b300-ubuntu2204` | Golden Image 태그 |

## 사용자 Application Image 파라미터

| 이름 | 필수 | 예시 | 설명 |
| --- | --- | --- | --- |
| `golden_image_uuid` | Y | `py311-cpu-ubuntu2204-20260727` | 승인된 Golden Image UUID |
| `git_url` | Y | `https://git.local/team/service.git` | 사용자 소스 저장소 |
| `git_revision` | Y | `main`, `v1.2.0`, commit SHA | 체크아웃할 Revision |
| `context_path` | Y | `.` | Docker Build Context 또는 소스 경로 |
| `requirements_lock_path` | Y | `requirements.lock` | 고정 의존성 파일 경로 |
| `accelerator` | Y | `cpu`, `cuda` | CPU/GPU Runtime 구분 |
| `gpu_model` | N | `b300`, `h100`, `a100` | GPU 모델 |
| `gpu_architecture` | N | `blackwell`, `hopper`, `ampere` | GPU 아키텍처 |
| `cuda_version` | N | `12.8` | CUDA 버전 |
| `minimum_driver_version` | N | `570.26` | 최소 NVIDIA Driver 버전 |
| `nvidia_driver_capabilities` | N | `compute,utility` | 컨테이너 런타임에 노출할 NVIDIA Driver Capability |
| `image_name` | N | `sample-api` | Harbor에 Push할 이미지명. 비우면 Git Repository 이름 사용 |
| `output_repository` | Y | `harbor.local/apps/service` | 애플리케이션 이미지 저장소 |
| `output_tag` | Y | `20260727-001` | 애플리케이션 이미지 태그 |
| `shell_type` | Y | `bash`, `sh` | 실행 Shell 종류 |
| `entrypoint_type` | Y | `module`, `script`, `binary`, `shell` | Entrypoint 해석 방식 |
| `entrypoint_value` | Y | `src.api`, `app.py` | 실행 대상 |
| `entrypoint_args` | N | `--port 8080` | 실행 인자 |
| `working_directory` | N | `/app` | 컨테이너 작업 디렉토리 |
| `run_as_user` | N | `10001` | 컨테이너 실행 사용자 UID |
| `environment_profile` | N | `production` | 환경 프로파일 |

## 파라미터 규칙

- 사용자는 Base Image를 직접 입력하지 않습니다.
- 사용자는 Golden Image UUID만 입력합니다.
- Workflow는 Catalog에서 `repository@digest`를 조회합니다.
- CPU는 `accelerator=cpu`로 관리하고 GPU 관련 필드는 비울 수 있습니다.
- GPU는 `accelerator=cuda`, `gpu_model`, `gpu_architecture`, `cuda_version`, `minimum_driver_version`으로 관리합니다.
- GPU Golden Image는 단순 Ubuntu 이미지가 아니라 CUDA/cuDNN/NCCL이 포함된 NVIDIA CUDA 계열 Base Image를 사용해야 합니다.
- B300은 현재 예시 GPU이며 `gpu_model=b300`, `gpu_architecture=blackwell`로 관리합니다.
- B300은 CUDA 12.8 이상을 기준으로 하며, CUDA 12.8 GA 기준 Linux Driver는 `570.26` 이상이어야 합니다.
- `git_revision`은 운영 배포 시 commit SHA 또는 불변 태그 사용을 권장합니다.
- `requirements.lock`이 없으면 빌드를 실패 처리합니다.
- `entrypoint_type`과 `entrypoint_value`는 필수입니다.
- `context_path`와 `requirements_lock_path`는 상대 경로만 허용합니다.
- `run_as_user`는 숫자 UID를 사용합니다.
