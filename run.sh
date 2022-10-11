#!/usr/bin/env bash

# Runs the built executable for a given target.
# Example:
#   ./run.sh //tools/python/pipenv:pipenv install funcy~=1.17

set -euo pipefail

target="$1"
shift

# Find where the built executable lives:
target_executable=$(bazel cquery "${target}" --output starlark --starlark:expr 'target.files_to_run.executable.path' 2>/dev/null)

# Execute it with the arguments provided:
"$target_executable" "$@"
