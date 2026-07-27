# Python Image Builder Standard

폐쇄망 환경에서 Python 애플리케이션 컨테이너 이미지를 표준화하기 위한 설계 저장소입니다.

## 핵심 원칙

- 관리자는 Python, OS, CUDA/cuDNN, 사내 CA가 포함된 Golden Image를 생성합니다.
- Golden Image는 UUID로 조회하고 실제 빌드에는 Harbor Repository와 Digest를 사용합니다.
- 사용자는 승인된 Golden Image UUID, Git 소스, `requirements.lock`, 실행 Shell/Entrypoint만 입력합니다.
- MLflow, PyTorch, NumPy 등 애플리케이션 패키지는 `requirements.lock`에서 관리합니다.
- 알람 및 Webhook 단계는 포함하지 않습니다.

## 구조

```text
관리자 Golden Image Builder
  -> 테스트/보안 검증
  -> Harbor Golden Repository
  -> Golden Image Catalog(UUID -> Repository@Digest)
  -> 사용자 Application Image Builder
  -> requirements.lock 오프라인 설치
  -> Harbor Application Repository
```

## 문서

- [아키텍처](docs/architecture.md)
- [파라미터 표준](docs/parameter-standard.md)
- [requirements.lock 정책](docs/requirements-lock-policy.md)
- [보고용 아키텍처 이미지](docs/python-image-builder-architecture.png)

## 운영 분리

```text
Golden Image
- Python Runtime
- OS
- CUDA / cuDNN (GPU 유형)
- 사내 CA
- 공통 런타임 도구

Application Image
- 사용자 소스
- requirements.lock
- 사용자 전용 패키지
- Shell / Entrypoint
```
