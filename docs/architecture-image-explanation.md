# Architecture Image Explanation

이 문서는 `폐쇄망 이미지 빌드 아키텍처` 이미지를 현업 담당자에게 설명할 때 사용하는 발표/공유용 가이드입니다.

![폐쇄망 이미지 빌드 아키텍처](images/python-image-build-architecture.png)

## 한 줄 요약

사용자는 빌드 대상만 입력하고, 실행 환경은 Golden Image Catalog에서 가져오며, BuildKit이 4 Layer 구조로 이미지를 빌드해 Harbor에 Digest 기준으로 저장합니다.

## 전체 설명 스크립트

```text
이 구조는 폐쇄망에서 애플리케이션 이미지를 안전하게 빌드하기 위한 아키텍처입니다.

사용자는 UI에서 이미지 이름, 사용자 ID, Golden Image, Source Repository,
Branch/Commit, Docker Tag, Requirements, Bash Shell/Entrypoint 같은
빌드 대상 정보만 입력합니다.

Golden Image는 운영자가 미리 승인한 실행 환경입니다.
여기에는 OS, Python, CUDA, GPU 호환 정보, 사내 CA 정책 같은 기준이 포함되어 있습니다.
사용자는 Base Image를 직접 입력하지 않고 Golden Image만 선택합니다.

Source Repository는 실제 애플리케이션 코드가 있는 저장소입니다.
여기에는 소스 코드, requirements.lock, 실행 스크립트가 들어 있습니다.

Argo Workflow는 사용자 입력을 검증하고, Source Repository를 Clone하고,
Golden Image Catalog에서 선택한 UUID를 실제 Harbor Digest 이미지로 변환합니다.

Nexus PyPI는 Argo 앞 단계가 아니라 BuildKit 빌드 중 Python Package Layer에서 사용됩니다.
requirements.lock 기준으로 패키지를 설치할 때 Nexus PyPI를 참조합니다.

Remote BuildKit은 Dockerfile을 빌드합니다.
이때 User Image는 Golden Image를 Base로 사용하고,
그 위에 4개 레이어를 쌓습니다.

4개 레이어는 Dependency Lock, Python Package, Application Source, Execution Config입니다.
requirements.lock을 소스보다 먼저 반영해서 패키지 캐시를 재사용할 수 있게 했습니다.

빌드가 끝나면 Harbor Registry에 Application Image가 Push되고,
Tag와 Digest가 기록됩니다.

마지막으로 Build Status, Created by, Image Path, Image Size,
GPU 여부, CUDA Version, Python Version 같은 값은 사용자가 입력하지 않고
자동 기록/조회 항목으로 관리합니다.
```

## 구성 요소별 설명

| 구성 요소 | 역할 | 설명 포인트 |
| --- | --- | --- |
| 사용자 등록 UI | 빌드 요청 정보 입력 | 사용자는 빌드 대상 정보만 입력합니다. |
| Source Repository | 애플리케이션 소스 | 코드, `requirements.lock`, `scripts/start.sh` 같은 실행 파일이 들어 있습니다. |
| Golden Image Catalog | 승인된 Base Image 조회 | UUID를 Harbor `repository@sha256:digest`로 변환합니다. |
| Nexus PyPI | 내부 패키지 저장소 | BuildKit 빌드 중 Python Package Layer에서만 사용합니다. |
| Argo Workflow | 빌드 오케스트레이션 | 입력 검증, 소스 Clone, Catalog 조회, 빌드 컨텍스트 생성을 담당합니다. |
| Remote BuildKit | 실제 이미지 빌드 | Dockerfile 빌드, Registry Cache 사용, Digest 추출을 수행합니다. |
| Harbor Registry | 최종 이미지 저장 | Application Image와 Build Cache를 저장합니다. |
| 자동 기록/조회 항목 | 결과 메타데이터 | 상태, 생성자, 이미지 경로, 크기, GPU/CUDA/Python 정보 등을 조회합니다. |

## 흐름 설명

```text
사용자 등록 UI
  -> Argo Workflow

Source Repository
  -> Argo Workflow

Golden Image Catalog
  -> Argo Workflow

Nexus PyPI
  -> BuildKit 빌드 중 Python Package Layer

Argo Workflow
  -> Remote BuildKit
  -> User Image Docker 4 Layer
  -> Harbor Registry
  -> 자동 기록 / 조회 항목
```

## Docker 4 Layer 설명

User Image는 Golden Image를 첫 번째 레이어로 다시 세지 않습니다.
Golden Image는 이미 운영에서 승인된 Base로 사용하고, 사용자 이미지에는 아래 4개 레이어를 추가합니다.

| 순서 | 레이어 | 목적 |
| --- | --- | --- |
| Base | Approved Golden Image | OS, Python, CUDA, GPU, 사내 CA 정책을 상속합니다. |
| 1 | Dependency Lock Layer | `requirements.lock`을 먼저 복사해 의존성 기준을 고정합니다. |
| 2 | Python Package Layer | Nexus PyPI에서 lock 기반으로 패키지를 설치합니다. |
| 3 | Application Source Layer | 사용자 애플리케이션 소스를 복사합니다. |
| 4 | Execution Config Layer | Bash Shell, Entrypoint, 실행 UID를 고정합니다. |

Runtime Policy는 Golden Image Base에서 상속하고, User Image는 `requirements.lock`부터 레이어를 나눕니다.
이 순서를 사용하는 이유는 `requirements.lock`이 바뀌지 않으면 Python Package Layer 캐시를 재사용할 수 있기 때문입니다.
소스 코드만 바뀐 경우에는 패키지 설치를 다시 하지 않고 빠르게 이미지를 다시 만들 수 있습니다.

## 자주 나오는 질문

### Golden Image와 Source Repository가 둘 다 필요한가?

둘 다 필요합니다.

```text
Golden Image = 어떤 실행 환경 위에서 돌릴지 선택
Source Repository = 어떤 애플리케이션 코드를 이미지에 넣을지 선택
```

최종 User Image는 `Golden Image + Source Repository + Requirements + Entrypoint 설정`으로 만들어집니다.

### Nexus PyPI는 왜 Argo 앞 단계가 아닌가?

Nexus PyPI는 소스를 가져오는 단계가 아니라 패키지를 설치하는 단계에서 사용합니다.
따라서 Argo가 전체 작업을 조율하고, BuildKit이 Dockerfile을 빌드하는 중 Python Package Layer에서 Nexus PyPI를 참조합니다.

### 사용자가 GPU/CUDA/Python Version을 입력해야 하나?

아닙니다.
이 값들은 사용자가 직접 입력하지 않고 Golden Image Catalog에서 자동 조회합니다.
사용자는 Golden Image UUID만 선택합니다.

### Bash Shell은 어디서 실행되나?

Argo Workflow 중간에서 사용자 Shell을 직접 실행하지 않습니다.
사용자 Shell은 Source Repository 안에 포함되고, 최종 이미지의 Entrypoint/CMD로 등록되어 컨테이너 시작 시 실행됩니다.

## 강조할 핵심 원칙

- 사용자는 빌드 대상만 입력합니다.
- Base Image는 승인된 Golden Image만 사용합니다.
- Source Repository와 Golden Image Catalog 조회는 Argo에서 처리합니다.
- Nexus PyPI는 BuildKit 빌드 중 Python Package Layer에서 사용합니다.
- User Image는 Golden Image Base 위에 4 Layer 정책으로 관리합니다.
- 결과는 Harbor Tag와 Digest, Build Report로 추적합니다.
