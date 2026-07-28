# Decision Record

이 문서는 폐쇄망 이미지 빌드 표준 구조를 정리하면서 확정한 주요 의사결정사항입니다.

## 한 줄 요약

운영자는 승인된 Golden Image를 만들고, 사용자는 Golden Image UUID와 소스/실행 정보만 입력하며, 실제 빌드는 Nexus와 BuildKit을 통해 Docker 4 Layer로 수행하고 Harbor Digest 기준으로 추적합니다.

## 의사결정사항

| 번호 | 의사결정 | 결정 내용 | 이유 |
| --- | --- | --- | --- |
| 1 | 이미지 빌드는 `golden`과 `user`로 분리 | Golden Image는 운영자가 만든 실행 환경, User Image는 사용자 애플리케이션 최종 이미지로 관리합니다. | 운영 표준 Runtime과 사용자 소스 변경을 분리하기 위해서입니다. |
| 2 | 사용자는 Base Image를 직접 입력하지 않음 | 사용자는 Golden Image UUID만 선택하고, Workflow가 Catalog에서 `repository@sha256:digest`를 조회합니다. | 임의 Base Image 사용을 막고 승인된 실행 환경만 사용하게 하기 위해서입니다. |
| 3 | 사용자 이미지는 Docker 4 Layer로 관리 | `Dependency Lock`, `Python Package`, `Application Source`, `Execution Config` 4개 레이어로 관리합니다. | Golden Image를 Base로 사용하므로 사용자 이미지에서는 애플리케이션 변경 레이어만 관리하기 위해서입니다. |
| 4 | Runtime Policy는 Golden Image에서 상속 | Python, CUDA, GPU, OS, CA, Runtime 정책은 Golden Image에 포함합니다. | 사용자 이미지마다 Runtime 정책이 흔들리지 않게 하기 위해서입니다. |
| 5 | Python 패키지는 Nexus PyPI만 사용 | 외부 PyPI는 사용하지 않고, Nexus PyPI와 `requirements.lock` 기준으로 설치합니다. | 폐쇄망 보안 정책과 패키지 재현성을 지키기 위해서입니다. |
| 6 | Source Repository는 사용자 이미지 빌드에 필요 | Golden Image는 실행 환경이고, Source Repository는 애플리케이션 코드입니다. | 최종 이미지는 실행 환경과 사용자 소스를 합쳐 만들어지기 때문입니다. |
| 7 | 사용자 Shell Script는 Git 소스 안에 포함 | Argo Workflow 중간에서 사용자 Shell을 직접 실행하지 않고, 최종 이미지의 Entrypoint/CMD로 등록합니다. | Workflow 실행 중 임의 Shell 실행을 줄이고 이미지 실행 계약으로 관리하기 위해서입니다. |
| 8 | GPU/CUDA/Python Version은 사용자가 직접 입력하지 않음 | GPU 여부, CUDA Version, Python Version은 Golden Image Catalog에서 자동 조회합니다. | 사용자가 호환성 값을 잘못 입력하는 문제를 막기 위해서입니다. |
| 9 | GPU 추가는 Workflow 복사가 아니라 Catalog 추가로 처리 | B300, H100, H200 등 GPU가 추가되면 Golden Image를 새로 만들고 Catalog Record만 추가합니다. | User Workflow를 GPU별로 복제하지 않고 운영 복잡도를 낮추기 위해서입니다. |
| 10 | Build 결과는 Tag보다 Digest 기준으로 추적 | Harbor Push 결과는 이미지 Tag와 Digest를 모두 기록하고, `build-report.json`에도 Digest를 남깁니다. | 같은 Tag가 바뀌더라도 실제 이미지 내용을 추적하기 위해서입니다. |
| 11 | 사용자 UI 입력값은 최소화 | 사용자는 빌드 대상과 실행 설정만 입력합니다. | 사용자가 운영 Runtime 정책을 직접 건드리지 않게 하기 위해서입니다. |
| 12 | 자동 기록/조회 항목은 사용자가 입력하지 않음 | Build Status, Created At, Image Path, Image Size, GPU/CUDA/Python 정보는 자동 기록합니다. | 감사 추적과 조회 정확도를 높이기 위해서입니다. |

## Golden Image와 User Image 역할

```text
Golden Image
= 운영자가 승인한 실행 환경
= OS, Python, CUDA, GPU, 사내 CA, Runtime 정책 포함

User Image
= Golden Image 위에 사용자 애플리케이션 소스를 올린 최종 이미지
= requirements.lock, 패키지, 소스, Entrypoint 포함
```

## User Image Docker 4 Layer

```text
Base. Approved Golden Image
1. Dependency Lock Layer
2. Python Package Layer
3. Application Source Layer
4. Execution Config Layer
```

Runtime Policy는 User Image 레이어로 세지 않습니다.
Runtime Policy는 Golden Image Base에서 상속되는 기준입니다.

## 사용자 UI 입력값

사용자 UI에서는 아래 항목만 입력받습니다.

```text
name
user-id
Golden Image
Source Repository
Branch / Commit
Docker Tag
Requirements
Bash Shell / Entrypoint
IDE 설정
Description
```

## 자동 기록/조회 항목

아래 항목은 사용자가 입력하지 않고 Workflow, Catalog, Harbor에서 자동 기록하거나 조회합니다.

```text
Build Status
Created by
Created at
Modified by
Modified at
Image Path
Image Size
GPU 여부
CUDA Version
Python Version
Framework
Image Digest
```

## GPU 추가 기준

GPU가 추가될 때는 User Workflow를 새로 만들지 않습니다.

```text
1. 운영자가 GPU별 Golden Image 생성
2. Harbor에 repository@sha256:digest로 Push
3. Golden Image Catalog에 새 UUID 추가
4. 사용자는 새 Golden Image UUID 선택
5. 기존 User Workflow 그대로 실행
```

## Shell 실행 기준

사용자 Shell은 Argo Workflow 중간에서 직접 실행하지 않습니다.

```text
Source Repository
  -> scripts/start.sh 포함
  -> Dockerfile CMD/Entrypoint로 등록
  -> 컨테이너 시작 시 실행
```

예시:

```text
shell-type       = bash
entrypoint-type  = shell
entrypoint-value = scripts/start.sh
entrypoint-args  = --port 8080
```

## 운영 설명용 문장

```text
이 구조는 사용자가 Base Image나 GPU/CUDA 값을 직접 입력하는 방식이 아닙니다.
운영자가 승인한 Golden Image를 Catalog에 등록하고,
사용자는 Golden Image UUID와 애플리케이션 소스/실행 정보만 입력합니다.
BuildKit은 Golden Image Base 위에 사용자 이미지 4 Layer를 구성하고,
최종 결과는 Harbor Tag와 Digest, Build Report로 추적합니다.
```
