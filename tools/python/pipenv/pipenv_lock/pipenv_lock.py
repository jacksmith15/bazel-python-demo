#!/usr/bin/env python

"""Lock a pipfile to requirements-lock.txt without venv access.

Based on https://github.com/pypa/pipenv/issues/2800#issuecomment-526212720
"""
import json
import sys
from functools import cache, partial
from pathlib import Path
from typing import TextIO

from pipenv.vendor.plette import Pipfile
from pipenv.vendor.requirementslib import Requirement


def main(pipfile: str = "Pipfile", pipfile_lock: str = "Pipfile.lock", output_path: str = "requirements-lock.txt"):
    """Convert a Pipfile.lock to requirements.txt format, without depending on a virtualenv.

    This is effectively a lightweight version of:

    ```
    pipenv lock --keep-outdated --requirements
    ```

    But additionally includes hashes in the generated lockfile.
    """
    verify_lockfile(pipfile, pipfile_lock)
    with open(output_path, "w", encoding="utf-8") as file:
        generate_lockfile(pipfile_lock, file)


def verify_lockfile(pipfile: str, pipfile_lock: str) -> None:
    """Check that Pipfile.lock is up-to-date."""
    with open(pipfile, "r", encoding="utf-8") as file:
        pipfile_hash = Pipfile.load(file).get_hash().value
    if pipfile_hash != load_lockfile(pipfile_lock)["_meta"]["hash"]["sha256"]:
        raise RuntimeError(
            f"The lockfile ({pipfile_lock} is not up-to-date with the pipfile ({pipfile}). "
            "Run `pipenv lock` before building."
        )


def generate_lockfile(pipfile_lock: str = "Pipfile.lock", out: TextIO = sys.stdout):
    """Generate the lockfile in requirements.txt format."""
    print_out = partial(print, file=out)

    lock = load_lockfile(pipfile_lock)
    for source in lock.get("_meta", {}).get("sources", []):
        url = source["url"]
        if source["name"] == "pypi":
            print_out(f"-i {url}")
        else:
            print_out(f"--extra-index-url {url}")
    for section in [lock["default"], lock["develop"]]:
        for name, entry in section.items():
            requirement = Requirement.from_pipfile(name, entry)
            print_out(requirement.as_line())


@cache
def load_lockfile(pipfile_lock: str) -> dict:
    return json.loads(Path(pipfile_lock).read_text(encoding="utf-8"))


if __name__ == "__main__":
    main(*sys.argv[1:])
