#!/usr/bin/env python

import shutil
import sys
from pathlib import Path


def main(repo_root: str, genfiles_root: str):
    """A script which copies the formatted outputs back into the sources.

    Can be invoked after running build with the `format` aspect, e.g.

        # Generate formatted files:
        bazel build //...:all --aspects //tools/format:aspects.bzl%format --output_groups=report

        # Copy them back (overwriting the unformatted files):
        bazel run //tools/format:apply $(git rev-parse --show-toplevel) $(bazel info bazel-genfiles)

    """
    formatter_output_dirs = find_formatter_output_dirs(genfiles_root)

    for unformatted_file, formatted_file in get_formatted_files(repo_root, genfiles_root).items():
        shutil.copy(formatted_file, unformatted_file)


def get_formatted_files(repo_root: str, genfiles_root: str) -> dict[Path, Path]:
    result = {}  # unformatted -> formatted
    for output_dir in find_formatter_output_dirs(genfiles_root):
        for formatted_file in output_dir.glob("**/*"):
            if formatted_file.is_dir():
                continue
            target = Path(repo_root) / formatted_file.relative_to(output_dir)
            if not target.exists():
                print(f"Skipping non-existent target: {target!r}")
            result[target] = formatted_file
    return result


def find_formatter_output_dirs(genfiles_root: str):
    root = Path(genfiles_root)
    for output_root in root.glob("**/__formatted_output"):
        if not output_root.is_dir():
            continue
        for output_dir in output_root.iterdir():
            if not output_dir.is_dir():
                continue
            yield output_dir


if __name__ == "__main__":
    main(*sys.argv[1:])
