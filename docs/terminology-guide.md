# 용어 정리 가이드

이 문서는 현업 설명 시 영어 용어를 그대로 읽기 어려운 경우를 위해 작성한 용어집입니다.
영어 원문, 한국어 발음, 쉬운 의미, 현재 프로젝트에서의 사용 위치를 함께 정리합니다.

## 디렉터리 구조 읽는 법

| 영어 표기 | 한국어 발음 | 의미 |
|---|---|---|
| `docker-yaml/` | 도커 야믈 | 전체 프로젝트 루트 디렉터리 |
| `README.md` | 리드미 마크다운 | 프로젝트 첫 설명 문서 |
| `kustomization.yaml` | 커스터마이제이션 야믈 | Kubernetes 리소스를 한 번에 적용하기 위한 Kustomize 설정 |
| `docs/` | 독스 | 설명 문서와 아키텍처 이미지 보관 디렉터리 |
| `docs/images/` | 독스 이미지즈 | 설명용 이미지 파일 보관 디렉터리 |
| `manifests/` | 매니페스트 | Catalog, UI Schema, 실제 서비스 실행 manifest 같은 Kubernetes 리소스 보관 디렉터리 |
| `manifests/core/` | 매니페스트 코어 | 공통 기반 리소스 보관 디렉터리 |
| `manifests/services/` | 매니페스트 서비스즈 | 실제 서비스 빌드 실행 manifest 보관 디렉터리 |
| `manifests/services/cpu/` | 매니페스트 서비스즈 씨피유 | CPU 서비스 이미지 빌드 실행 manifest 보관 디렉터리 |
| `manifests/services/gpu/` | 매니페스트 서비스즈 지피유 | GPU 서비스 이미지 빌드 실행 manifest 보관 디렉터리 |
| `scripts/` | 스크립츠 | Workflow 안에서 실행되는 스크립트 보관 디렉터리 |
| `scripts/admin/` | 스크립츠 어드민 | 관리자 영역에서 사용하는 검증, Dockerfile 생성, 빌드 결과 기록 스크립트 |
| `scripts/user/` | 스크립츠 유저 | 사용자가 Workflow 실행 요청을 제출할 때 쓰는 예시 스크립트 |
| `workflows/` | 워크플로즈 | Argo WorkflowTemplate YAML 보관 디렉터리 |
| `workflows/golden-image-build.yaml` | 골든 이미지 빌드 야믈 | 관리자 Golden Image 빌드 WorkflowTemplate |
| `workflows/user-image-build.yaml` | 유저 이미지 빌드 야믈 | 사용자 Application Image 빌드 WorkflowTemplate |

참고로 `directory`는 한국어로 보통 `디렉터리` 또는 `디렉토리`라고 읽습니다.
문서에서는 표준 표기에 가까운 `디렉터리`를 사용하지만, 현업 대화에서는 `디렉토리`라고 말해도 의미는 같습니다.

### 디렉터리 구조를 처음 볼 때 설명하는 순서

디렉터리 구조는 파일 목록을 외우기 위한 것이 아니라, “어떤 파일이 어떤 책임을 갖는지”를 설명하기 위한 지도입니다.
현업 설명에서는 아래 순서로 보면 이해가 쉽습니다.

1. `README.md`
   - 프로젝트 전체 목적과 사용 흐름을 먼저 보는 문서입니다.
   - 처음 보는 사람은 이 파일에서 `golden`과 `user`가 왜 나뉘는지 이해하면 됩니다.

2. `docs/`
   - 구조를 설명하기 위한 문서 영역입니다.
   - 아키텍처 이미지, 의사결정사항, 파라미터 기준, 용어 정리 같은 설명 자료가 들어갑니다.

3. `workflows/`
   - 실제 Argo WorkflowTemplate이 들어가는 영역입니다.
   - 관리자용 Golden Image 빌드와 사용자용 User Image 빌드를 분리해서 관리합니다.

4. `scripts/`
   - Workflow 안에서 실행되는 세부 처리 로직입니다.
   - YAML 안에 긴 명령을 모두 넣지 않고, 검증/소스 가져오기/Dockerfile 생성/빌드 결과 기록을 스크립트로 분리합니다.

5. `manifests/`
   - Kubernetes에 적용하거나 실제 서비스 빌드 실행에 사용할 리소스 파일 영역입니다.
   - Golden Image Catalog, 사용자 UI Schema, CPU/GPU 서비스 실행 manifest가 여기에 들어갑니다.

### 디렉터리별 책임

| 디렉터리 | 책임 | 주로 보는 사람 |
|---|---|---|
| `docs/` | 설명, 의사결정, 아키텍처 공유 | 현업 담당자, 운영자, 개발자 |
| `workflows/` | Argo에서 실행할 표준 절차 정의 | 플랫폼 운영자, DevOps 담당자 |
| `scripts/admin/` | 관리자 영역 빌드 처리 로직 | 플랫폼 운영자 |
| `scripts/user/` | 사용자가 서비스 빌드를 제출할 때 쓰는 실행 편의 스크립트 | 사용자, 현업 담당자 |
| `manifests/core/` | Catalog, UI Schema 같은 공통 리소스 | 운영자, 시스템 연동 담당자 |
| `manifests/services/` | 실제 서비스 빌드 실행 manifest | 운영자, 서비스 담당자 |

### 설명할 때 쓰는 쉬운 문장

```text
이 프로젝트는 크게 문서, 실행 템플릿, 실행 스크립트, Kubernetes 적용 파일로 나뉩니다.
docs는 설명 자료이고, workflows는 Argo가 실행할 표준 절차입니다.
scripts는 Workflow 안에서 실제 일을 하는 처리 로직이고, manifests는 Catalog와 실제 서비스 실행 manifest처럼 Kubernetes에 적용하는 파일입니다.
```

## 핵심 이미지 빌드 용어

| 영어 표기 | 한국어 발음 | 쉬운 의미 | 우리 구조에서의 의미 |
|---|---|---|---|
| Golden Image | 골든 이미지 | 운영자가 승인한 기준 이미지 | OS, CA, Python, CUDA, 공통 런타임 기준을 담은 관리자 이미지 |
| User Image | 유저 이미지 / 사용자 이미지 | 사용자가 실제 배포할 애플리케이션 이미지 | Golden Image 위에 소스, 패키지, 실행 설정을 올린 최종 이미지 |
| Base Image | 베이스 이미지 | 가장 밑바탕이 되는 이미지 | Golden Image가 시작하는 CUDA/Ubuntu 등 기준 이미지 |
| Runtime Image | 런타임 이미지 | 실행 환경 이미지 | User Image가 상속받는 승인된 Golden Image |
| Application Image | 애플리케이션 이미지 | 앱 실행용 최종 이미지 | 사용자가 Harbor에 Push하는 최종 결과물 |
| Image Layer | 이미지 레이어 | Docker 이미지 안의 변경 단위 | 캐시와 재현성을 위해 역할별로 나눈 단계 |
| Docker Tag | 도커 태그 | 이미지 버전 이름 | 예: `my-api:20260728-001` |
| Image Digest | 이미지 다이제스트 | 이미지 내용을 기준으로 만든 고정 해시 | `sha256:...` 형식이며 재현성과 검증 기준 |
| Registry | 레지스트리 | 이미지를 저장하는 저장소 | Harbor가 이 역할을 수행 |
| Harbor | 하버 | 사내 컨테이너 이미지 저장소 | Golden Image, User Image, Build Cache 저장 |
| Nexus | 넥서스 | 사내 패키지 저장소 | Python 패키지를 외부 PyPI 대신 여기서만 다운로드 |
| Bitbucket | 빗버킷 | 사내 Git 저장소 | 사용자 애플리케이션 소스를 가져오는 위치 |
| BuildKit | 빌드킷 | Docker 이미지를 빌드하는 엔진 | Argo Pod 안에서 원격 BuildKit에 빌드 요청 |
| Build Cache | 빌드 캐시 | 이전 빌드 결과 재사용 데이터 | requirements.lock이나 소스가 같으면 빌드 시간을 줄임 |

## Argo / Kubernetes 용어

| 영어 표기 | 한국어 발음 | 쉬운 의미 | 우리 구조에서의 의미 |
|---|---|---|---|
| Argo Workflow | 아르고 워크플로 | Kubernetes 위에서 여러 작업을 순서대로 실행하는 도구 | 이미지 빌드 절차 전체를 실행 |
| WorkflowTemplate | 워크플로 템플릿 | 재사용 가능한 Workflow 정의 | `golden`, `user` 빌드 템플릿으로 분리 |
| DAG | 대그 | 작업 간 의존 관계 그래프 | 어떤 Task가 먼저/나중에 실행되는지 정의 |
| Task | 태스크 | Workflow 안의 한 작업 단위 | 검증, Dockerfile 생성, 빌드, 결과 기록 등 |
| Template | 템플릿 | Task가 실행할 실제 작업 정의 | Script나 Container 실행 내용 |
| Namespace | 네임스페이스 | Kubernetes 리소스를 구분하는 공간 | 현재 기준은 `argo` |
| ServiceAccount | 서비스 어카운트 | Pod가 사용할 권한 계정 | 현재 기준은 `argo-kserver` |
| PVC | 피브이씨 | Pod 간 공유 디스크 요청 | 소스, 생성 파일, 빌드 결과 공유 |
| Secret | 시크릿 | 비밀번호, 인증키 같은 민감정보 | Git, Harbor, Nexus 인증정보 |
| ConfigMap | 컨피그맵 | 일반 설정값 보관 리소스 | Golden Image Catalog, UI Schema, 스크립트 배포 |
| Manifest | 매니페스트 | Kubernetes에 적용하는 YAML/JSON 파일 | 실제 서비스 실행, Catalog, ConfigMap 파일 |

## 패키지 / 의존성 용어

| 영어 표기 | 한국어 발음 | 쉬운 의미 | 우리 구조에서의 의미 |
|---|---|---|---|
| requirements.lock | 리콰이어먼츠 락 | 정확한 패키지 버전을 고정한 파일 | 사용자 빌드 필수 입력값 |
| requirements.txt | 리콰이어먼츠 텍스트 | 일반 Python 패키지 목록 파일 | 현재 운영 구조에서는 직접 사용하지 않고 lock 생성을 위한 원천으로만 봄 |
| Wheel | 휠 | Python 빌드 완료 패키지 파일 | 폐쇄망에서 설치 가능한 패키지 단위 |
| Wheelhouse | 휠하우스 | Wheel 파일을 모아둔 디렉터리 | 패키지를 미리 받아두거나 검증할 때 사용하는 공간 |
| Lock File | 락 파일 | 버전을 고정한 의존성 파일 | `requirements.lock`을 의미 |
| Dependency | 디펜던시 | 의존 패키지 | 앱 실행에 필요한 Python 패키지 |
| Dependency Layer | 디펜던시 레이어 | 패키지 설치 레이어 | User Image 1~2단계에서 관리 |

## GPU / Runtime 용어

| 영어 표기 | 한국어 발음 | 쉬운 의미 | 우리 구조에서의 의미 |
|---|---|---|---|
| GPU | 지피유 | 그래픽 연산 장치 | B300 등 가속기 사용 여부 |
| CUDA | 쿠다 | NVIDIA GPU 연산 런타임 | B300은 CUDA 12.8 이상 기준 |
| cuDNN | 큐디엔엔 | 딥러닝용 NVIDIA 라이브러리 | Golden Image 메타데이터로 관리 |
| NCCL | 엔씨씨엘 | GPU 간 통신 라이브러리 | 멀티 GPU 학습/추론 시 필요한 런타임 정보 |
| Driver | 드라이버 | GPU를 운영체제에서 사용할 수 있게 하는 구성요소 | B300 기준 최소 Driver Version을 Catalog에 기록 |
| Architecture | 아키텍처 | CPU/GPU 구조 | 예: `amd64`, `blackwell` |
| Runtime Environment | 런타임 엔바이런먼트 | 실행 환경 | Python, CUDA, Torch 버전 조합 |

## 우리 구조 설명용 한 줄 표현

| 표현 | 설명할 때 쓰는 문장 |
|---|---|
| Golden Image | 운영자가 먼저 만든 승인된 실행 환경입니다. |
| User Image | 사용자가 Golden Image 위에 자기 소스와 패키지를 올려 만든 최종 이미지입니다. |
| Digest 기반 | Tag 이름이 아니라 실제 이미지 내용 해시로 검증합니다. |
| requirements.lock | 패키지 버전을 고정해서 같은 결과가 다시 나오게 하는 기준 파일입니다. |
| Nexus only | 외부 인터넷이 아니라 사내 Nexus에서만 Python 패키지를 받습니다. |
| BuildKit Cache | 같은 패키지나 소스는 다시 빌드하지 않도록 캐시를 재사용합니다. |
| Catalog | 사용자가 직접 CUDA/Driver를 고르는 대신 승인된 Golden Image 목록에서 선택하게 하는 기준표입니다. |

## 현업 설명 예시

```text
우리 구조는 이미지를 관리자 영역과 사용자 영역으로 나눕니다.
관리자는 Golden Image를 만들고, 사용자는 승인된 Golden Image UUID를 선택해서 User Image를 만듭니다.
사용자는 Git Repository, Docker Tag, requirements.lock, 실행 Shell/Entrypoint만 입력하면 됩니다.
CUDA, Driver, Python 같은 런타임 기준은 Golden Image Catalog에서 상속합니다.
패키지는 외부 PyPI가 아니라 사내 Nexus에서만 받고, 최종 이미지는 Harbor에 Digest 기준으로 저장합니다.
```
