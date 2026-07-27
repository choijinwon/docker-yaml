# requirements.lock Policy

이 문서는 폐쇄망 Python 애플리케이션 이미지 빌드에서 `requirements.lock`을 사용하는 정책을 정의합니다.

## 원칙

- 애플리케이션 패키지는 Golden Image에 포함하지 않습니다.
- MLflow, PyTorch, NumPy 등 서비스별 의존성은 `requirements.lock`에서 관리합니다.
- 빌드 중 외부 인터넷 접근은 허용하지 않습니다.
- 패키지는 내부 PyPI Mirror 또는 내부 Wheelhouse에서만 설치합니다.
- 운영 배포용 `requirements.lock`은 리뷰와 승인 대상입니다.

## 파일 규칙

권장 형식:

```text
package-name==1.2.3
another-package==4.5.6
```

금지 또는 제한:

- 버전 범위: `numpy>=1.26`
- 최신 버전 참조: `package`
- 외부 URL 직접 참조
- Git URL 직접 참조
- 빌드 시점 동적 해석이 필요한 옵션

## 설치 방식

폐쇄망 기본 설치 방식:

```bash
pip install \
  --no-index \
  --find-links=/opt/wheelhouse \
  --requirement requirements.lock
```

내부 PyPI Mirror를 사용하는 경우:

```bash
pip install \
  --index-url=https://pypi.internal/simple \
  --trusted-host=pypi.internal \
  --requirement requirements.lock
```

## 검증 기준

- `requirements.lock` 파일이 존재해야 합니다.
- 모든 패키지는 정확한 버전으로 고정되어야 합니다.
- 내부 저장소에서 해석 가능한 패키지만 허용합니다.
- 빌드 로그에 외부 인터넷 다운로드가 없어야 합니다.
- 결과 이미지에는 설치된 패키지 목록을 SBOM 또는 텍스트로 남기는 것을 권장합니다.
