import argparse
import subprocess
import sys
from contextlib import contextmanager

from hash import generate_build_graph, hash_build_graph

# TODO:
# - output=packages for human readable
# - output=targets for informing test runner

def main():
    parser = argparse.ArgumentParser(description="Generate a diff from Bazel build graphs.")
    parser.add_argument("-o", "--output", choices=["package", "target"], default="target")
    parser.add_argument("-s", "--strategy", choices=["checkout", "commit"], default="checkout")
    parser.add_argument("source_commit", nargs=1)
    parser.add_argument("target_commit", nargs="?")
    args = parser.parse_args()
    assert args.strategy != "commit", "--strategy=commit not yet supported"

    source_hash, target_hash = get_hashes(args.source_commit, args.target_commit)

    affected = get_affected(source_hash, target_hash, packages=(args.output == "package"))
    print("\n".join(affected))


def get_hashes(source_commit: str, target_commit: str | None = None) -> tuple[dict, dict]:
    with checkout(target_commit):
        target_hash = generate_hash()
    with checkout(source_commit):
        source_hash = generate_hash()
    return source_hash, target_hash


def generate_hash() -> dict:
    return hash_build_graph(generate_build_graph())


def get_affected(source_hash: dict, target_hash: dict, packages: bool = True) -> list[str]:
    targets = diff_build_graph(source_hash, target_hash)
    if not packages:
        return targets
    return subprocess.run(
        ["bazel", "query", "--output=package", " union ".join(targets)],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.splitlines()



def diff_build_graph(source_hash: dict, target_hash: dict) -> list[str]:
    return [key for key, value in target_hash.items() if source_hash.get(key) != value]


@contextmanager
def checkout(commit: str | None = None):
    if not commit:
        yield
        return
    stash = has_staged_or_unstaged_changes()
    if stash:
        run(["git", "stash", "push", "--include-untracked"])
    try:
        original_commit = run(["git", "rev-parse", "--abbrev-ref", "HEAD"])
        run(["git", "checkout", commit])
        try:
            yield
        finally:
            run(["git", "checkout", original_commit])
    finally:
        if stash:
            run(["git", "stash", "pop", "--index"])


def has_staged_or_unstaged_changes() -> bool:
    return bool(
        run(["git", "status", "--porcelain"])
    )


def run(cmd: list[str]) -> str:
    try:
        return subprocess.run(cmd, check=True, capture_output=True, text=True).stdout.strip()
    except subprocess.CalledProcessError as exc:
        print(exc.stdout, file=sys.stderr)
        print(exc.stderr, file=sys.stderr)
        raise exc


if __name__ == "__main__":
    main()
