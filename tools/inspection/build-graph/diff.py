"""Tool to identify which targets are affected between two commits.

Implementation notes:

    Currently this actively checks out the relevant commits, analyses the build graph and
    produces a set of hashes for each commit.

    Two alternative strategies have some advantages, particularly if this process slows when
    the repository grows:

    1. Require that an up-to-date hash file is committed (with pre-commit and CI). This
       reduces the work required, and doesn't require use of stash and checkout
    2. Store the hash file for each commit in an external data-store, e.g. S3, with
       fallback to the current strategy. This might be appropriate if the hash-file grows
       so large it shouldn't be committed.

"""
import argparse
import subprocess
import sys
from contextlib import contextmanager

from hash import generate_build_graph, hash_build_graph


def main():
    parser = argparse.ArgumentParser(description="Generate a diff from Bazel build graphs.")
    parser.add_argument(
        "-p",
        "--packages",
        action="store_true",
        default=False,
        help="Simplify output by displaying affected packages rather than targets.",
    )
    parser.add_argument(
        "source_ref", default="HEAD", nargs="?", help="The git ref to compare changes to. Defaults to HEAD."
    )
    parser.add_argument(
        "target_ref",
        nargs="?",
        help="The git ref containing changes. Omit to use current state, including staged and unstaged changes.",
    )
    args = parser.parse_args()

    source_ref = get_merge_base(args.source_ref, args.target_ref)
    source_hash, target_hash = get_hashes(source_ref, args.target_ref)

    affected = get_affected(source_hash, target_hash, packages=args.packages)
    print("\n".join(affected))


def get_hashes(source_ref: str, target_ref: str | None = None) -> tuple[dict, dict]:
    with checkout(target_ref):
        target_hash = generate_hash()
    with checkout(source_ref):
        source_hash = generate_hash()
    return source_hash, target_hash


def generate_hash() -> dict:
    return hash_build_graph(generate_build_graph())


def get_affected(source_hash: dict, target_hash: dict, packages: bool = True) -> list[str]:
    targets = diff_build_graph(source_hash, target_hash)
    if not packages:
        return targets
    return run(
        ["bazel", "query", "--output=package", " union ".join(targets)],
    ).splitlines()


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
    return bool(run(["git", "status", "--porcelain"]))


def get_merge_base(source_ref: str, target_ref: str | None = None) -> str:
    target_ref = target_ref or "HEAD"
    return run(["git", "merge-base", source_ref, target_ref])


def run(cmd: list[str]) -> str:
    try:
        return subprocess.run(cmd, check=True, capture_output=True, text=True).stdout.strip()
    except subprocess.CalledProcessError as exc:
        print(exc.stdout, file=sys.stderr)
        print(exc.stderr, file=sys.stderr)
        raise exc


if __name__ == "__main__":
    main()
