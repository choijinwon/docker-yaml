# 이미지 빌드 표준 구조 발표 문장

이 문서는 `폐쇄망 이미지 빌드 표준 구조`를 발표할 때 짧게 설명하기 위한 문서입니다.
상세 설명은 `image-build-standard-structure-explanation.md`를 참고합니다.

## 30초 요약

```text
이 구조는 폐쇄망에서 이미지 빌드를 표준화하기 위한 구조입니다.

운영자는 먼저 Golden Image를 만들고 Catalog에 등록합니다.
사용자는 임의 Base Image를 고르지 않고, 승인된 Golden Image UUID만 선택합니다.

소스는 내부 Bitbucket에서 가져오고, Python 패키지는 내부 Nexus에서만 받습니다.
이미지는 Remote BuildKit으로 빌드하고, 최종 결과는 Harbor에 Tag와 Digest 기준으로 저장합니다.

핵심은 Golden Image, requirements.lock, Digest를 기준으로
폐쇄망에서도 재현 가능하고 감사 가능한 이미지 빌드를 만드는 것입니다.
```

## 1분 발표 문장

```text
이 이미지는 폐쇄망 환경에서 Golden Image와 User Image를 분리해
이미지 빌드를 표준화하는 구조를 보여줍니다.

왼쪽 관리자 영역에서는 운영자가 Python, CUDA, OS, GPU, 사내 CA 같은 기준을 정해
Golden Image를 만듭니다.
Golden Image는 사용자가 직접 수정하는 이미지가 아니라,
운영에서 승인한 표준 실행 환경입니다.

오른쪽 사용자 영역에서는 사용자가 Golden Image UUID, Git Repository,
requirements.lock, 실행 Shell/Entrypoint 정보를 입력합니다.
사용자는 Base Image나 CUDA/Driver 값을 직접 입력하지 않고,
Catalog에 등록된 APPROVED Golden Image만 선택합니다.

빌드 과정에서는 소스는 내부 Bitbucket에서 가져오고,
패키지는 외부 PyPI가 아니라 내부 Nexus에서만 가져옵니다.
BuildKit이 이미지를 빌드하고 Harbor에 Push하면,
결과 이미지는 Tag와 Digest 기준으로 기록됩니다.

이 구조의 핵심은 운영자가 Runtime 기준을 먼저 승인하고,
사용자는 승인된 기준 위에서 애플리케이션 이미지만 만드는 것입니다.
그래서 폐쇄망에서도 재현성, 보안성, 감사 추적을 확보할 수 있습니다.
```

## 단계별 짧은 설명

| 순서 | 설명 문장 |
| --- | --- |
| 1 | 운영자가 Golden Image를 만들어 표준 실행 환경을 준비합니다. |
| 2 | Golden Image는 Harbor Digest 기준으로 고정하고 Catalog에 등록합니다. |
| 3 | 사용자는 Catalog에서 APPROVED Golden Image UUID를 선택합니다. |
| 4 | 애플리케이션 소스는 내부 Bitbucket에서 가져옵니다. |
| 5 | Python 패키지는 내부 Nexus에서만 설치합니다. |
| 6 | `requirements.lock`으로 패키지 버전을 고정합니다. |
| 7 | Shell/Entrypoint는 Argo에서 직접 실행하지 않고 Docker 이미지 실행 설정으로 반영합니다. |
| 8 | BuildKit이 이미지를 빌드하고 Harbor에 Push합니다. |
| 9 | 최종 결과는 Tag와 Digest, Build Report로 추적합니다. |

## 영역별 발표 포인트

| 영역 | 발표 문장 |
| --- | --- |
| 전체 흐름 | 폐쇄망 내부의 Bitbucket, Nexus, BuildKit, Harbor, Catalog만 사용합니다. |
| 관리자 영역 | 운영자가 CPU/GPU Runtime 기준을 Golden Image로 승인합니다. |
| 사용자 영역 | 사용자는 승인된 Golden Image 위에 애플리케이션 소스와 실행 설정만 올립니다. |
| requirements.lock | 패키지 버전을 고정해 빌드 결과가 매번 달라지는 문제를 줄입니다. |
| Shell / Entrypoint | 사용자 Shell은 Workflow 중간에서 실행하지 않고 최종 컨테이너 실행 명령으로만 사용합니다. |
| Harbor | Golden Image, Application Image, Build Cache를 역할별로 분리해 저장합니다. |
| Catalog | UUID, Digest, Runtime 정보, 승인 상태를 관리하는 기준표입니다. |

## 꼭 강조할 문장

```text
사용자는 Base Image를 직접 선택하지 않습니다.
운영에서 승인한 Golden Image UUID만 선택합니다.
```

```text
Tag만으로 이미지를 관리하지 않고,
Digest 기준으로 실제 빌드 결과를 검증하고 기록합니다.
```

```text
외부 인터넷을 사용하지 않고,
Bitbucket, Nexus, BuildKit, Harbor 같은 내부 시스템만 사용합니다.
```

```text
requirements.lock은 패키지 버전을 고정하기 위한 운영 기준 파일입니다.
```

## 질문이 나왔을 때 짧은 답변

### 왜 Golden Image를 따로 만드나요?

```text
사용자마다 Base Image와 Runtime을 다르게 쓰면 운영 기준이 흔들리기 때문입니다.
Golden Image로 Python, CUDA, OS, CA, GPU 기준을 먼저 고정합니다.
```

### 왜 Digest가 필요한가요?

```text
Tag는 같은 이름이어도 이미지 내용이 바뀔 수 있습니다.
Digest는 이미지 내용을 기준으로 한 고정값이라 재현성과 감사 추적에 필요합니다.
```

### 왜 requirements.lock을 쓰나요?

```text
requirements.lock은 패키지 버전을 고정합니다.
그래서 같은 소스와 같은 lock 파일이면 같은 패키지 기준으로 다시 빌드할 수 있습니다.
```

### 사용자 Shell은 어디서 실행되나요?

```text
Argo Workflow 중간에서 직접 실행하지 않습니다.
소스 Repository에 포함된 Shell 경로나 Entrypoint 정보를 최종 Docker 이미지 실행 설정으로 반영합니다.
```

### GPU가 추가되면 어떻게 하나요?

```text
User Workflow를 새로 만들지 않습니다.
관리자가 GPU별 Golden Image를 만들고 Catalog에 새 UUID와 Digest를 등록하면 됩니다.
```
