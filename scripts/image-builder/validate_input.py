import re
import sys
from pathlib import Path
from urllib.parse import urlparse


def fail(message: str) -> None:
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

if not repository_url:
    fail("Repository URL is empty")

if not git_revision:
    fail("git-revision is empty")

if not context_path or context_path.startswith("/") or ".." in context_path.split("/"):
    fail("context-path must be a relative path without ..")

if not requirements_lock_path or requirements_lock_path.startswith("/") or ".." in requirements_lock_path.split("/"):
    fail("requirements-lock-path must be a relative path without ..")

if image_name and not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._/-]{0,127}", image_name):
    fail(f"Invalid image-name: {image_name}")

if shell_type not in {"bash", "sh"}:
    fail("shell-type must be bash or sh")

if entrypoint_type not in {"module", "script", "binary", "shell"}:
    fail("entrypoint-type must be module, script, binary, or shell")

if not entrypoint_value:
    fail("entrypoint-value is empty")

if not working_directory.startswith("/"):
    fail("working-directory must be absolute")

if not re.fullmatch(r"[0-9]+", run_as_user):
    fail("run-as-user must be numeric")

if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}", environment_profile):
    fail(f"Invalid environment-profile: {environment_profile}")

if re.match(r"^[^@]+@[^:]+:", repository_url):
    path = repository_url.split(":", 1)[1]
else:
    path = urlparse(repository_url).path

repository_name = Path(path).name
if repository_name.endswith(".git"):
    repository_name = repository_name[:-4]

if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}", repository_name or ""):
    fail(f"Invalid repository name: {repository_name}")

Path("/tmp/repository-name.txt").write_text(repository_name, encoding="utf-8")
print(f"repository-name={repository_name}")
