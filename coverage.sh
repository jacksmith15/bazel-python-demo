#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

COVERAGE_REPORT_DIR="reports/coverage"

# Run tests in coverage mode:
bazel coverage //...

# Convert combined LCOV file to HTML (depends on lcov being installed):
bazel run -- @lcov//:genhtml --rc lcov_branch_coverage=1 -o $COVERAGE_REPORT_DIR bazel-out/_coverage/_coverage_report.dat

# Open the coverage report:
xdg-open "${COVERAGE_REPORT_DIR}/index.html"
