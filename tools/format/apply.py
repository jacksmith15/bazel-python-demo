#!/usr/bin/env python

import argparse
import difflib
import os
import shutil
from pathlib import Path
from typing import Callable


# TODO: Figure out the arguments


def main():
    """A script which copies the formatted outputs back into the sources.

    Can be invoked after running build with the `format` aspect, e.g.

        # Generate formatted files:
        bazel build //...:all --aspects //tools/format:aspects.bzl%format --output_groups=report

        # Copy them back (overwriting the unformatted files):
        bazel run //tools/format:apply $(git rev-parse --show-toplevel) $(bazel info bazel-genfiles)

    """
    args = parse_args()
    formatter_output_dirs = find_formatter_output_dirs(args.genfiles_root)

    for unformatted_file, formatted_file in get_formatted_files(args.workspace_root, args.genfiles_root).items():
        formatted_content = formatted_file.read_text(encoding="utf-8")

        if args.diff:
            unformatted_content = unformatted_file.read_text(encoding="utf-8")
            name = unformatted_file.relative_to(args.workspace_root)
            for line in difflib.unified_diff(
                unformatted_content.splitlines(),
                formatted_content.splitlines(),
                fromfile=f"a/{name}",
                tofile=f"b/{name}",
                lineterm="",
            ):
                print(color_line(line))
        else:
            with open(unformatted_file, "w", encoding="utf-8") as file:
                file.write(formatted_content)


def parse_args():
    parser = argparse.ArgumentParser(description="Copy formatted bazel outputs back into sources.")
    parser.add_argument(
        "workspace_root",
        help="Root of the workspace",
    )
    parser.add_argument(
        "genfiles_root",
        help="Root of the bazel genfiles outputs.",
    )
    parser.add_argument(
        "-d",
        "--diff",
        action="store_true",
        help="Just print the diff.",
    )

    return parser.parse_args()


def get_formatted_files(workspace_root: str, genfiles_root: str) -> dict[Path, Path]:
    result = {}  # unformatted -> formatted
    for output_dir in find_formatter_output_dirs(genfiles_root):
        for formatted_file in output_dir.glob("**/*"):
            if formatted_file.is_dir():
                continue
            target = Path(workspace_root) / formatted_file.relative_to(output_dir)
            if not target.exists():
                print(f"Skipping non-existent target: {target!r}")
            if target in result:
                # Keep the latest formatted version of a file (if there are multiple). This avoids situations where a
                # renamed target accidentally reverts changes.
                if os.path.getmtime(formatted_file) <= os.path.getmtime(result[target]):
                    continue
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


def color_line(line: str) -> str:
    if line.startswith("+"):
        return color(GREEN)(line)
    if line.startswith("-"):
        return color(RED)(line)
    if line.startswith("^"):
        return color(BLUE)(line)
    return line


BLUE = "\033[94m"
GREEN = "\033[92m"
RED = "\033[91m"
RESET = "\033[0m"


def color(color_code: str) -> Callable[[str], str]:
    def _wrap(string: str):
        return f"{color_code}{string}{RESET}"

    return _wrap


if __name__ == "__main__":
    main()
