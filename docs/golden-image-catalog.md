# Golden Image Catalog

Golden Image Catalog는 사용자가 입력한 UUID를 실제 Harbor Image Digest로 변환하기 위한 매핑 데이터입니다.

## 역할

- 승인된 Golden Image 목록 관리
- UUID와 `repository@digest` 매핑
- Python/OS/CPU/GPU/CUDA 조합 검색
- Deprecated 이미지 차단
- 사용자 Workflow에서 Base Image 직접 입력 제거

## Record 예시

```json
[
  {
    "uuid": "py311-cpu-ubuntu2204-20260727",
    "status": "active",
    "runtime": {
      "python": "3.11.9",
      "os": "ubuntu",
      "osVersion": "22.04",
      "architecture": "amd64",
      "accelerator": "cpu"
    },
    "image": {
      "repository": "harbor.local/platform/golden",
      "tag": "py311-cpu-ubuntu2204",
      "digest": "sha256:1111111111111111111111111111111111111111111111111111111111111111"
    }
  },
  {
    "uuid": "py311-cuda128-b300-ubuntu2204-20260727",
    "status": "active",
    "runtime": {
      "python": "3.11.9",
      "os": "ubuntu",
      "osVersion": "22.04",
      "architecture": "amd64",
      "accelerator": "cuda",
      "gpuModel": "b300",
      "gpuArchitecture": "blackwell",
      "cudaVersion": "12.8",
      "minimumDriverVersion": "570.26",
      "nvidiaDriverCapabilities": "compute,utility"
    },
    "image": {
      "repository": "harbor.local/platform/golden",
      "tag": "py311-cuda128-b300-ubuntu2204",
      "digest": "sha256:0000000000000000000000000000000000000000000000000000000000000000"
    }
  }
]
```

## 조회 결과

사용자 Workflow는 UUID 조회 후 다음 값을 사용합니다.

```text
harbor.local/platform/golden@sha256:<digest>
```

태그는 사람이 식별하기 위한 보조 정보이며, 실제 빌드 기준은 Digest입니다.

## 상태 값

| 상태 | 의미 |
| --- | --- |
| `active` | 신규 빌드에 사용 가능 |
| `deprecated` | 기존 서비스 유지 가능, 신규 빌드 제한 |
| `blocked` | 보안/운영 이슈로 사용 금지 |

## 운영 규칙

- Catalog는 GitOps 방식으로 변경 이력을 남깁니다.
- Digest가 바뀌면 새 UUID를 발급합니다.
- 기존 UUID의 Digest를 조용히 바꾸지 않습니다.
- `blocked` 상태는 사용자 Workflow에서 즉시 실패 처리합니다.
- B300 Catalog Record는 `gpuArchitecture=blackwell`과 `cudaVersion>=12.8`을 명시합니다.
- B300 Golden Image는 일반 Ubuntu Base가 아니라 내부 Harbor에 미러링된 NVIDIA CUDA Runtime/Devel 계열 이미지를 사용합니다.
- CPU Golden Image는 CUDA 관련 필드 없이 `accelerator=cpu`만 사용합니다.
- 다른 GPU 타입은 새로운 Catalog Record를 추가해서 확장합니다.
- Workflow는 GPU 종류를 직접 분기하지 않고 Catalog에서 조회된 `repository@digest`를 사용합니다.
