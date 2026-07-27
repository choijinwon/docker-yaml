# Python Image Builder Architecture

이 문서는 폐쇄망 환경에서 Python 애플리케이션 컨테이너 이미지를 표준화하기 위한 전체 구조를 설명합니다.

## 목표

- 사용자가 임의의 Base Image를 선택하지 않도록 Golden Image를 중앙에서 관리합니다.
- Python Runtime, OS, CUDA/cuDNN, 사내 CA, 공통 도구는 관리자 영역에서 고정합니다.
- 애플리케이션 패키지는 사용자 `requirements.lock`으로 분리합니다.
- 실제 빌드는 태그가 아니라 `repository@digest`를 사용해 재현성을 확보합니다.
- 알람, Webhook, 외부 인터넷 다운로드 단계는 기본 범위에서 제외합니다.

## 전체 흐름

```text
Admin
  -> Golden Image Workflow
  -> Smoke Test / Security Scan
  -> Harbor Golden Repository
  -> Golden Image Catalog

User
  -> Application Build Request
  -> Golden Image UUID Resolve
  -> Git Source Checkout
  -> requirements.lock Offline Install
  -> Harbor Application Repository
```

## 관리자 영역

관리자는 Golden Image를 생성하고 검증한 뒤 Catalog에 등록합니다.

Golden Image에 포함되는 항목:

- OS Base
- Python Runtime
- CUDA/cuDNN 또는 CPU Runtime
- 사내 CA 인증서
- pip 설정
- 공통 빌드/런타임 도구
- 내부 Wheelhouse 접근 설정

Golden Image에 포함하지 않는 항목:

- MLflow
- PyTorch
- NumPy
- pandas
- 사용자 서비스 코드
- 사용자별 Shell 또는 Entrypoint

## 사용자 영역

사용자는 애플리케이션 이미지 생성에 필요한 최소 입력만 제공합니다.

- Golden Image UUID
- Git Repository URL
- Git Revision
- Source Context Path
- `requirements.lock`
- 실행 Shell 또는 Entrypoint
- Output Image Name/Tag

빌드 시스템은 Golden Image UUID를 Catalog에서 조회하고, 실제 빌드에는 `repository@digest`를 사용합니다.

## 재현성 기준

- Golden Image는 Digest로 고정합니다.
- 애플리케이션 의존성은 `requirements.lock`으로 고정합니다.
- 외부 인터넷 다운로드는 허용하지 않습니다.
- 내부 패키지 저장소 또는 Wheelhouse만 사용합니다.
- 빌드 요청 파라미터와 Catalog Record를 함께 보관합니다.

## 산출물

- Golden Image: `harbor.local/platform/python-golden:<tag>@sha256:<digest>`
- Catalog Record: UUID와 Digest 매핑
- Application Image: `harbor.local/apps/<service>:<tag>@sha256:<digest>`
