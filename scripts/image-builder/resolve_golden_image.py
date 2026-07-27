import json
import re
import sys
from pathlib import Path


# Resolve the approved Golden Image into a concrete repository@sha256 digest.
# If GOLDEN_IMAGE_UUID is provided, the catalog wins. Otherwise RUNTIME_IMAGE is used.


def fail(message: str) -> None:
    # Fail fast so the workflow never builds from an unapproved or mutable base image.
    print(message, file=sys.stderr)
    sys.exit(1)


def env(name: str) -> str:
    import os

    return os.environ.get(name, "").strip()


golden_uuid = env("GOLDEN_IMAGE_UUID")
runtime_image = env("RUNTIME_IMAGE")
catalog_path = Path(env("CATALOG_PATH") or "/catalog/golden-image-catalog.json")

# Preferred path: users select a Golden Image UUID, not a raw base image.
if golden_uuid:
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
    runtime_image = f'{image["repository"]}@{image["digest"]}'

# The final base image must be immutable. Tags alone are not accepted.
if not re.fullmatch(r".+@sha256:[0-9a-f]{64}", runtime_image):
    fail(f"runtime-image must use repository@sha256 digest: {runtime_image}")

parent_digest = runtime_image.rsplit("@", 1)[1]

# Argo exposes these files as output parameters for downstream tasks and reports.
Path("/tmp/runtime-image.txt").write_text(runtime_image, encoding="utf-8")
Path("/tmp/parent-image-digest.txt").write_text(parent_digest, encoding="utf-8")
print(f"runtime-image={runtime_image}")
