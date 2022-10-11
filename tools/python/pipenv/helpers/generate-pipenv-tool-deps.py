#!/usr/bin/env python3

"""Helper script for upgrading pipenv repository rule dependencies.

The output of this script can be pasted into tools/python/pipenv/repositories.bzl to upgrade
pipenv. This saves time manually checking available versions and wheel hashes.

Usage:

    python generate-pipenv-tool-deps.py PIPENV_VERSION

"""

import hashlib
import json
import shutil
import subprocess
import sys
import textwrap
from contextlib import contextmanager
from dataclasses import dataclass
from email.parser import HeaderParser
from functools import cached_property
from pathlib import Path
from typing import List
from urllib.request import urlopen
from uuid import uuid4
from zipfile import ZipFile


@dataclass
class Requirement:
    wheel_filename: str
    name: str
    version: str
    sha256: str

    @cached_property
    def url(self) -> str:
        with urlopen(f"https://pypi.org/pypi/{self.name}/{self.version}/json") as response:
            assert response.status == 200
            result = json.loads(response.read())
        for url_section in result["urls"]:
            if url_section["filename"] == self.wheel_filename:
                return url_section["url"]
        assert False, f"Couldn't resolve download url for {self}"


def main():
    pipenv_version = sys.argv[1]
    requirements = get_pipenv_requirements(pipenv_version)
    output_requirements(requirements)


def output_requirements(requirements: List[Requirement]) -> None:
    output_lines = [
        "_RULE_DEPS = [",
        indent(1)("# The following deps are auto-generated using tools/python/pipenv/generate-pipenv-tool-deps.py")
    ] + [
        render_rule_dep(requirement)
        for requirement in requirements
    ] + ["]"]
    print("\n".join(output_lines))


def render_rule_dep(requirement: Requirement) -> str:
    return f"""    (
        "{requirement.name}",
        "{requirement.url}",
        "{requirement.sha256}",
    ),"""


def indent(level: int = 1):
    def _wrap(text: str):
        return textwrap.indent(text, " " * level * 4)
    return _wrap


def get_pipenv_requirements(pipenv_version: str) -> List[Requirement]:

    with tmp_dir("pipenv-deps") as directory:

        subprocess.run(
            [
                sys.executable,
                "-m",
                "pip",
                "download",
                "--only-binary",
                ":all",
                "-d",
                directory,
                f"pipenv=={pipenv_version}"
            ],
            check=True,
            capture_output=True,
            text=True,
        )

        result: List[Requirement] = []

        for sub_path in directory.iterdir():
            assert sub_path.suffix == ".whl"
            result.append(parse_wheel(sub_path))
        return result


def parse_wheel(path: Path) -> Requirement:
    with open(path, "rb") as file:
        with ZipFile(file) as zip_file:
            for wheel_file in zip_file.namelist():
                wheel_file_path = Path(wheel_file)
                if wheel_file_path.name == "METADATA" and wheel_file_path.parts[0].endswith(".dist-info"):
                    wheel_metadata = HeaderParser().parsestr(zip_file.read(str(wheel_file_path)).decode("utf-8"))
                    return Requirement(
                        wheel_filename=str(path.name),
                        name=wheel_metadata["Name"],
                        version=wheel_metadata["Version"],
                        sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                    )
    assert False, f"Could not parse wheel metadata from {path}"


@contextmanager
def tmp_dir(name_prefix: str):
    uuid = uuid4()

    directory = Path(f"/tmp/{name_prefix}-{uuid}")

    try:
        directory.mkdir()
        yield directory
    finally:
        shutil.rmtree(directory)


if __name__ == "__main__":
    main()
