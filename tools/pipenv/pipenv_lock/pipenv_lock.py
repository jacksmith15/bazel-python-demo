#!/usr/bin/env python

"""Lock a pipfile to requirements-lock.txt without venv access.

Based on https://github.com/pypa/pipenv/issues/2800#issuecomment-526212720
"""
import json
import sys
from functools import partial
from pathlib import Path
from typing import TextIO


def main(pipfile_lock: str = "Pipfile.lock", output_path: str = "requirements-lock.txt"):
    with open(output_path, "w", encoding="utf-8") as file:
        generate_lockfile(pipfile_lock, file)


def generate_lockfile(pipfile_lock: str = "Pipfile.lock", out: TextIO = sys.stdout):
    from pipenv.vendor.requirementslib import Requirement
    print_out = partial(print, file=out)

    path = Path(pipfile_lock)
    lock = json.loads(path.read_text(encoding="utf-8"))
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


if __name__ == "__main__":
    main(*sys.argv[1:])
