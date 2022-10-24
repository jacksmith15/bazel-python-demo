import json
import subprocess
import sys
from functools import lru_cache
from hashlib import sha256
from io import StringIO
from pathlib import Path
from typing import IO
from xml.etree import ElementTree


# TODO: Test with a single pipenv version change

def main() -> None:
    result = hash_build_graph(parse_graph_from_args())
    print(json.dumps(result, indent=2, sort_keys=True))


def parse_graph_from_args() -> str | IO[str]:
    if len(sys.argv) == 1:
        result = subprocess.run(
            ["bazel", "query", "--output=xml", "deps(//...)"],
            check=True,
            capture_output=True,
            text=True,
        )
        return StringIO(result.stdout)
    if sys.argv[1] == "-":
        return sys.stdin
    return sys.argv[1]


def hash_build_graph(data: str | IO[str]) -> dict[str, str]:
    graph = ElementTree.parse(data).getroot()
    targets_by_name = {element.attrib["name"]: element for element in graph}

    @lru_cache(maxsize=None)
    def get_hash(name: str) -> str:
        element = targets_by_name[name]
        sha = sha256()
        sha.update(ElementTree.tostring(element, encoding="utf-8"))

        if element.tag == "source-file":
            if element.attrib["name"].startswith("//"):
                sha.update(hash_source_file(element.attrib["location"]))
            else:
                sha.update(hash_external_file(element.attrib["name"]))


        for child in element:
            if child.tag == "rule-input":
                sha.update(get_hash(child.attrib["name"]).encode("utf-8"))
        return sha.hexdigest()

    return {
        name: get_hash(name)
        for name, target in targets_by_name.items()
        if name.startswith("//") and target.tag == "rule"
    }


def hash_source_file(location: str) -> bytes:
    sha = sha256()
    path = location.rsplit(":", 2)[0]  # Location includes line and column suffix
    with open(path, "rb") as file:
        while True:
            block = file.read(sha.block_size)
            if not block:
                break
            sha.update(block)
    return sha.hexdigest().encode("utf-8")


def hash_external_file(name: str) -> bytes:
    repository = name.removeprefix("@").split("//")[0]
    return external_repository_hash(repository)


@lru_cache(maxsize=None)
def external_repository_hash(repo_name: str) -> bytes:
    marker_path = get_output_base() / "external" / f"@{repo_name}.marker"
    content = marker_path.read_bytes()
    sha = sha256()
    sha.update(content)
    return sha.hexdigest().encode("utf-8")


@lru_cache(maxsize=1)
def get_output_base() -> Path:
    return Path(
        subprocess.run(
            ["bazel", "info", "output_base"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
    )


if __name__ == "__main__":
    main()
