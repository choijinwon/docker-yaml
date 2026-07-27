import json
import re
import sys
from pathlib import Path


# Resolve the approved Golden Image into a concrete repository@sha256 digest.
# User image builds must select a deployed Golden Image from the Catalog by UUID.


def fail(message: str) -> None:
    # Fail fast so the workflow never builds from an unapproved or mutable base image.
    print(message, file=sys.stderr)
    sys.exit(1)


def env(name: str) -> str:
    import os

    return os.environ.get(name, "").strip()


golden_uuid = env("GOLDEN_IMAGE_UUID")
catalog_path = Path(env("CATALOG_PATH") or "/catalog/golden-image-catalog.json")

if not golden_uuid:
    fail("golden-image-uuid is required for user image builds")

if not catalog_path.exists():
    fail("Golden Image Catalog ConfigMap is not mounted")

catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
matches = [item for item in catalog if item.get("uuid") == golden_uuid]
if not matches:
    fail(f"Golden Image UUID not found: {golden_uuid}")

record = matches[0]
if record.get("status") != "active":
    fail(f"Golden Image is not active: {golden_uuid}")

image = record["image"]
runtime = record.get("runtime", {})
runtime_image = f'{image["repository"]}@{image["digest"]}'

# The final base image must be immutable. Tags alone are not accepted.
if not re.fullmatch(r".+@sha256:[0-9a-f]{64}", runtime_image):
    fail(f"runtime-image must use repository@sha256 digest: {runtime_image}")

parent_digest = runtime_image.rsplit("@", 1)[1]

# Argo exposes these files as output parameters for downstream tasks and reports.
Path("/tmp/runtime-image.txt").write_text(runtime_image, encoding="utf-8")
Path("/tmp/parent-image-digest.txt").write_text(parent_digest, encoding="utf-8")
Path("/tmp/architecture.txt").write_text(runtime.get("architecture", ""), encoding="utf-8")
Path("/tmp/accelerator.txt").write_text(runtime.get("accelerator", ""), encoding="utf-8")
Path("/tmp/gpu-model.txt").write_text(runtime.get("gpuModel", ""), encoding="utf-8")
Path("/tmp/gpu-architecture.txt").write_text(runtime.get("gpuArchitecture", ""), encoding="utf-8")
Path("/tmp/cuda-version.txt").write_text(runtime.get("cudaVersion", ""), encoding="utf-8")
Path("/tmp/minimum-driver-version.txt").write_text(runtime.get("minimumDriverVersion", ""), encoding="utf-8")
Path("/tmp/nvidia-driver-capabilities.txt").write_text(
    runtime.get("nvidiaDriverCapabilities")
    or ("compute,utility" if runtime.get("accelerator") == "cuda" else ""),
    encoding="utf-8",
)
print(f"runtime-image={runtime_image}")
