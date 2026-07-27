# Parameter Standard

이 문서는 관리자 Golden Image Workflow와 사용자 Application Image Workflow에서 사용하는 파라미터 표준을 정의합니다.

## 관리자 Golden Image 파라미터

| 이름 | 필수 | 예시 | 설명 |
| --- | --- | --- | --- |
| `golden_image_uuid` | Y | `py311-cpu-ubuntu2204-20260727` | Catalog에서 조회할 고유 ID |
| `python_version` | Y | `3.11.9` | Golden Image에 포함할 Python 버전 |
| `os_family` | Y | `ubuntu` | OS 계열 |
| `os_version` | Y | `22.04` | OS 버전 |
| `accelerator` | Y | `cpu`, `cuda` | CPU/GPU Runtime 구분 |
| `cuda_version` | N | `12.1` | GPU 이미지일 때 CUDA 버전 |
| `cudnn_version` | N | `8.9` | GPU 이미지일 때 cuDNN 버전 |
| `base_image` | Y | `harbor.local/base/ubuntu:22.04` | 내부 Harbor에 저장된 Base Image |
| `output_repository` | Y | `harbor.local/platform/python-golden` | Golden Image 저장소 |
| `output_tag` | Y | `py311-cpu-ubuntu2204` | Golden Image 태그 |

## 사용자 Application Image 파라미터

| 이름 | 필수 | 예시 | 설명 |
| --- | --- | --- | --- |
| `golden_image_uuid` | Y | `py311-cpu-ubuntu2204-20260727` | 승인된 Golden Image UUID |
| `git_url` | Y | `https://git.local/team/service.git` | 사용자 소스 저장소 |
| `git_revision` | Y | `main`, `v1.2.0`, commit SHA | 체크아웃할 Revision |
| `context_path` | Y | `.` | Docker Build Context 또는 소스 경로 |
| `requirements_lock_path` | Y | `requirements.lock` | 고정 의존성 파일 경로 |
| `entrypoint` | N | `python app.py` | 컨테이너 실행 명령 |
| `output_repository` | Y | `harbor.local/apps/service` | 애플리케이션 이미지 저장소 |
| `output_tag` | Y | `20260727-001` | 애플리케이션 이미지 태그 |

## 파라미터 규칙

- 사용자는 Base Image를 직접 입력하지 않습니다.
- 사용자는 Golden Image UUID만 입력합니다.
- Workflow는 Catalog에서 `repository@digest`를 조회합니다.
- `git_revision`은 운영 배포 시 commit SHA 또는 불변 태그 사용을 권장합니다.
- `requirements.lock`이 없으면 빌드를 실패 처리합니다.
- `entrypoint`가 비어 있으면 Golden Image 기본 Entrypoint를 사용합니다.
