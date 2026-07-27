import re
import sys
from pathlib import Path
from urllib.parse import urlparse


# Validate the user-facing workflow parameters before any network or build work.
# This script also derives a safe repository name used as the default image name.


def fail(message: str) -> None:
    # Argo marks the step as failed when the script exits with a non-zero code.
    print(message, file=sys.stderr)
    sys.exit(1)


def env(name: str) -> str:
    import os

    return os.environ.get(name, "").strip()


repository_url = env("REPOSITORY_URL")
git_revision = env("GIT_REVISION")
context_path = env("CONTEXT_PATH")
requirements_lock_path = env("REQUIREMENTS_LOCK_PATH")
image_name = env("IMAGE_NAME")
shell_type = env("SHELL_TYPE")
entrypoint_type = env("ENTRYPOINT_TYPE")
entrypoint_value = env("ENTRYPOINT_VALUE")
working_directory = env("WORKING_DIRECTORY")
run_as_user = env("RUN_AS_USER")
environment_profile = env("ENVIRONMENT_PROFILE")

# Required source input. Without this, the workflow has nothing to clone.
if not repository_url:
    fail("Repository URL is empty")

# Branch, tag, or commit SHA to build. The clone script handles both branch and SHA.
if not git_revision:
    fail("git-revision is empty")

# Keep paths inside the checked-out repository. Absolute paths or '..' could escape
# the build context and accidentally include files that should not be built.
if not context_path or context_path.startswith("/") or ".." in context_path.split("/"):
    fail("context-path must be a relative path without ..")

if not requirements_lock_path or requirements_lock_path.startswith("/") or ".." in requirements_lock_path.split("/"):
    fail("requirements-lock-path must be a relative path without ..")

# image_name is optional. When empty, the repository name becomes the image name.
if image_name and not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._/-]{0,127}", image_name):
    fail(f"Invalid image-name: {image_name}")

# Only support shells that are expected to exist in the approved Golden Image.
if shell_type not in {"bash", "sh"}:
    fail("shell-type must be bash or sh")

# Entrypoint mode controls how ENTRYPOINT_VALUE is converted into the final CMD.
if entrypoint_type not in {"module", "script", "binary", "shell"}:
    fail("entrypoint-type must be module, script, binary, or shell")

if not entrypoint_value:
    fail("entrypoint-value is empty")

if not working_directory.startswith("/"):
    fail("working-directory must be absolute")

# Run as a numeric UID to avoid depending on OS user names inside base images.
if not re.fullmatch(r"[0-9]+", run_as_user):
    fail("run-as-user must be numeric")

if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}", environment_profile):
    fail(f"Invalid environment-profile: {environment_profile}")

# Support both SSH-style Git URLs and normal HTTP(S) URLs.
if re.match(r"^[^@]+@[^:]+:", repository_url):
    path = repository_url.split(":", 1)[1]
else:
    path = urlparse(repository_url).path

repository_name = Path(path).name
if repository_name.endswith(".git"):
    repository_name = repository_name[:-4]

if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}", repository_name or ""):
    fail(f"Invalid repository name: {repository_name}")

# Argo reads this file as the output parameter for later tasks.
Path("/tmp/repository-name.txt").write_text(repository_name, encoding="utf-8")
print(f"repository-name={repository_name}")
