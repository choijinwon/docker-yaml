# User UI Guide

이 문서는 User Image Build 화면에서 사용자에게 보여줄 입력 항목과 설명 기준을 정의합니다.

## UI 입력 그룹

User Image Build 화면은 다음 그룹으로 나누는 것을 권장합니다.

| 그룹 | 입력 항목 | 설명 |
| --- | --- | --- |
| Golden Image | `golden-image-uuid` | 운영에서 배포한 Golden Image 선택 |
| Source | `bitbucket-address-user-code`, `git-revision`, `context-path` | 빌드할 사용자 소스 위치 |
| Dependency | `requirements-lock-path` | 고정 패키지 목록 |
| Output Image | `image-name`, `image-tag`, `registry-project` | Harbor에 Push될 결과 이미지 |
| Runtime Command | `shell-type`, `entrypoint-type`, `entrypoint-value`, `entrypoint-args`, `working-directory`, `run-as-user` | 컨테이너 실행 방식 |

## Runtime Command 설명

사용자 UI에서 가장 헷갈리기 쉬운 영역은 Shell/Entrypoint입니다.

이 영역은 “이미지를 어떻게 실행할지”를 정하는 부분입니다. Dockerfile 마지막 단계에서 `CMD`로 반영됩니다.

| UI 라벨 | 파라미터 | 필수 | UI 타입 | 설명 |
| --- | --- | --- | --- | --- |
| Shell | `shell-type` | Y | select | 컨테이너 실행 명령을 감쌀 Shell |
| Entrypoint 방식 | `entrypoint-type` | Y | select | 실행 대상을 해석하는 방식 |
| 실행 대상 | `entrypoint-value` | Y | text | 모듈명, 스크립트 경로, 바이너리명, Shell 스크립트 경로 |
| 실행 인자 | `entrypoint-args` | N | text | 실행 대상 뒤에 붙일 옵션 |
| 작업 디렉토리 | `working-directory` | N | text | 컨테이너 내부 실행 위치 |
| 실행 UID | `run-as-user` | N | number | 컨테이너 실행 사용자 UID |

## Shell 옵션

| 값 | 설명 | 권장 |
| --- | --- | --- |
| `bash` | Bash Shell. 대부분의 Python 서비스에서 권장 | Y |
| `sh` | POSIX Shell. 가벼운 이미지나 Bash가 없는 이미지에서 사용 | N |

UI 안내 문구:

```text
컨테이너가 시작될 때 실행 명령을 감싸는 Shell입니다.
일반 Python 서비스는 bash를 권장합니다.
```

## Entrypoint 방식

| 값 | 사용 예시 | 생성되는 실행 명령 |
| --- | --- | --- |
| `module` | `entrypoint-value=src.api` | `python -m src.api` |
| `script` | `entrypoint-value=app.py` | `python app.py` |
| `binary` | `entrypoint-value=gunicorn` | `gunicorn` |
| `shell` | `entrypoint-value=scripts/start.sh` | `bash scripts/start.sh` |

UI 안내 문구:

```text
애플리케이션을 어떤 방식으로 실행할지 선택합니다.
Python 모듈 실행이면 module, .py 파일 실행이면 script, 실행 파일이면 binary, 시작 스크립트면 shell을 선택합니다.
```

## 추천 기본값

일반 Python API 서비스는 다음 기본값을 권장합니다.

```text
shell-type        = bash
entrypoint-type   = module
entrypoint-value  = src.api
entrypoint-args   =
working-directory = /app
run-as-user       = 10001
```

## UI 검증 규칙

- `shell-type`은 `bash` 또는 `sh`만 허용합니다.
- `entrypoint-type`은 `module`, `script`, `binary`, `shell`만 허용합니다.
- `entrypoint-value`는 비어 있으면 안 됩니다.
- `working-directory`는 `/app`처럼 절대 경로여야 합니다.
- `run-as-user`는 숫자 UID여야 합니다.
- 사용자 UI에는 GPU/CUDA/Driver 입력칸을 만들지 않습니다. 이 값들은 Golden Image Catalog에서 자동 조회됩니다.

## 화면 표시 예시

```text
Runtime Command

Shell
[ bash v ]
컨테이너가 시작될 때 실행 명령을 감싸는 Shell입니다. 일반 Python 서비스는 bash를 권장합니다.

Entrypoint 방식
[ module v ]
Python 모듈 실행이면 module, .py 파일 실행이면 script, 실행 파일이면 binary, 시작 스크립트면 shell을 선택합니다.

실행 대상
[ src.api ]

실행 인자
[ --port 8080 ]

작업 디렉토리
[ /app ]

실행 UID
[ 10001 ]
```
