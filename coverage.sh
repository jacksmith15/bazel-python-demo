#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

COVERAGE_REPORT_DIR="reports/coverage"

if ! command -v genhtml &> /dev/null
then
    echo "lcov not installed. Please install with e.g. 'brew install lcov'."
    exit 1
fi

# Run tests in coverage mode:
bazel coverage //...

# Convert combined LCOV file to HTML (depends on lcov being installed):
genhtml -o $COVERAGE_REPORT_DIR bazel-out/_coverage/_coverage_report.dat

# Open the coverage report:
xdg-open "${COVERAGE_REPORT_DIR}/index.html"
