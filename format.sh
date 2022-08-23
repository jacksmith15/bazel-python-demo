#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Generate formatted versions as outputs:
bazel build //... --aspects //tools/format:aspects.bzl%format --output_groups=report

# Overwrite our source files with the formatted outputs:
bazel run //tools/format:apply -- $@ $(git rev-parse --show-toplevel) $(bazel info bazel-genfiles)
