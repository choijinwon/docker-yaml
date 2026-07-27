import re
import sys
from pathlib import Path


# Validate Golden Image build parameters.
# Golden images are admin-owned base runtime images, so they do not accept user Git source.


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def env(name: str) -> str:
    import os

    return os.environ.get(name, "").strip()


image_type = env("IMAGE_TYPE") or "golden"
golden_image_uuid = env("GOLDEN_IMAGE_UUID")
base_image = env("BASE_IMAGE")
python_version = env("PYTHON_VERSION")
os_family = env("OS_FAMILY")
os_version = env("OS_VERSION")
architecture = env("ARCHITECTURE")
accelerator = env("ACCELERATOR")
gpu_model = env("GPU_MODEL")
gpu_architecture = env("GPU_ARCHITECTURE")
cuda_version = env("CUDA_VERSION")
minimum_driver_version = env("MINIMUM_DRIVER_VERSION")
image_name = env("IMAGE_NAME")
image_tag = env("IMAGE_TAG")
common_os_packages = env("COMMON_OS_PACKAGES")
run_as_user = env("RUN_AS_USER")
environment_profile = env("ENVIRONMENT_PROFILE")

if image_type != "golden":
    fail("golden image workflow requires image-type=golden")

if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}", golden_image_uuid or ""):
    fail("golden-image-uuid is required and must be a safe identifier")

if not re.fullmatch(r".+@sha256:[0-9a-fA-F]{64}", base_image or ""):
    fail("base-image must use immutable repository@sha256 digest")

if not re.fullmatch(r"[0-9]+(\.[0-9]+){1,2}", python_version or ""):
    fail("python-version must look like 3.11 or 3.11.9")

if os_family not in {"ubuntu", "rocky", "ubi"}:
    fail("os-family must be ubuntu, rocky, or ubi")

if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,31}", os_version or ""):
    fail("os-version is required")

if architecture not in {"amd64", "arm64"}:
    fail("architecture must be amd64 or arm64")

if accelerator not in {"cpu", "cuda"}:
    fail("accelerator must be cpu or cuda")

if accelerator == "cuda":
    if not gpu_model:
        fail("gpu-model is required when accelerator is cuda")
    if not gpu_architecture:
        fail("gpu-architecture is required when accelerator is cuda")
    if not cuda_version:
        fail("cuda-version is required when accelerator is cuda")
    if not minimum_driver_version:
        fail("minimum-driver-version is required when accelerator is cuda")

if gpu_model.lower() == "b300":
    if gpu_architecture.lower() != "blackwell":
        fail("B300 must use gpu-architecture=blackwell")
    if not re.fullmatch(r"(12\.(8|9)|13(\.[0-9]+)?)", cuda_version):
        fail("B300 requires CUDA 12.8 or newer")

if image_name and not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._/-]{0,127}", image_name):
    fail(f"Invalid image-name: {image_name}")

if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}", image_tag or ""):
    fail("image-tag is required and must be a safe tag")

if common_os_packages and not re.fullmatch(r"[A-Za-z0-9+_. -]+", common_os_packages):
    fail("common-os-packages contains unsupported characters")

if not re.fullmatch(r"[0-9]+", run_as_user or ""):
    fail("run-as-user must be numeric")

if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}", environment_profile or ""):
    fail(f"Invalid environment-profile: {environment_profile}")

# Reuse the common build script contract. Golden images are not derived from Git repos,
# so this stable name is only used for report/cache wiring.
Path("/tmp/repository-name.txt").write_text("golden-image", encoding="utf-8")
print(f"golden-image-uuid={golden_image_uuid}")
