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
- [Golden Image Catalog](docs/golden-image-catalog.md)
- [보고용 아키텍처 이미지](docs/python-image-builder-architecture.png)
- [관리자 Golden Image Workflow](workflows/admin-golden-image-builder.yaml)
- [사용자 Application Image Workflow](workflows/user-application-image-builder.yaml)
- [6단계 Docker Layer Image Build Workflow](workflows/python-image-build-6-layer.yaml)
- [운영형 Workflow 개선 포인트](docs/operational-workflow-improvement.md)

## 저장소 구조

```text
docker-yaml/
├── README.md
├── docs/
│   ├── architecture.md
│   ├── golden-image-catalog.md
│   ├── parameter-standard.md
│   ├── python-image-builder-architecture.png
│   └── requirements-lock-policy.md
├── examples/
│   ├── golden-image-catalog.example.json
│   └── requirements.lock.example
├── manifests/
│   ├── golden-image-catalog.configmap.yaml
│   └── golden-image-dockerfile.configmap.yaml
├── kustomization.yaml
├── scripts/
│   └── image-builder/
│       ├── build_and_push_image.sh
│       ├── create_6_layer_dockerfile.sh
│       ├── fetch_source.sh
│       ├── resolve_golden_image.py
│       ├── validate_input.py
│       └── write_result.sh
└── workflows/
    ├── admin-golden-image-builder.yaml
    ├── python-image-build-6-layer.yaml
    └── user-application-image-builder.yaml
```

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

## 사용 흐름

1. 관리자가 `workflows/admin-golden-image-builder.yaml`로 Golden Image를 빌드합니다.
2. 빌드 결과는 Harbor `repository@digest`로 고정하고 Catalog에 UUID와 함께 등록합니다.
3. 사용자는 Golden Image UUID와 Git 소스, `requirements.lock`, 실행 명령만 제출합니다.
4. `workflows/user-application-image-builder.yaml`가 Catalog를 조회해 Golden Image Digest 기반으로 애플리케이션 이미지를 만듭니다.

## 6단계 Workflow 적용

`workflows/python-image-build-6-layer.yaml`는 인라인 스크립트 대신 `scripts/image-builder/`의 분리된 스크립트를 호출합니다.

```text
kubectl apply -k .
kubectl apply -f workflows/python-image-build-6-layer.yaml
```

`kustomization.yaml`은 `scripts/image-builder/` 파일을 `python-image-builder-scripts` ConfigMap으로 생성합니다.
