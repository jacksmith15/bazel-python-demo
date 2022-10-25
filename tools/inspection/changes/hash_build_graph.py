import argparse
import json
import subprocess
from functools import lru_cache
from hashlib import sha256
from pathlib import Path
from xml.etree import ElementTree


def main() -> None:
    args = parse_args()
    build_graph = get_build_graph(args)
    result = hash_build_graph(build_graph)
    print(json.dumps(result, indent=2, sort_keys=True))


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate a hash file from Bazel's build graph.",
    )
    parser.add_argument(
        "file",
        type=argparse.FileType("r"),
        nargs="?",
        help=(
            "A file containing a bazel `deps` query output in xml format with relative "
            "locations. Omit to generate the build graph automatically."
        ),
    )
    return parser.parse_args()


def get_build_graph(args) -> ElementTree.Element:
    if args.file:
        return ElementTree.parse(args.file).getroot()
    result = subprocess.run(
        ["bazel", "query", "--output=xml", "--relative_locations", "deps(//...)"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    return ElementTree.fromstring(result)


def hash_build_graph(graph: ElementTree.Element) -> dict[str, str]:
    targets_by_name = {element.attrib["name"]: element for element in graph}

    @lru_cache(maxsize=None)
    def get_hash(name: str) -> str:
        element = targets_by_name[name]
        sha = sha256()
        sha.update(ElementTree.tostring(element, encoding="utf-8"))

        if element.tag == "source-file":
            sha.update(hash_source_file(element.attrib["location"]))

        seen_repos: set[str] = set()

        for child in element:
            if child.tag != "rule-input":
                continue
            if repo := repository_name(child.attrib["name"]):
                # We don't traverse source files for external repositories - the files
                # likely don't exist outside of build time. Besides this, they contain
                # elements with absolute paths, which makes hashing not portable.
                # Instead, we include the repo marker hash for any external repositories.
                if repo in seen_repos:
                    continue
                sha.update(external_repository_hash(repo))
                seen_repos.update(repo)
            else:
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


def repository_name(name: str) -> str:
    if name.startswith("@"):
        return name.split("//", 1)[0].removeprefix("@")
    return ""


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
