import os
import sys
from contextlib import contextmanager
from pathlib import Path

import pytest

from coverage import Coverage
# from coverage_lcov.converter import Converter


@contextmanager
def record_coverage():
    """Record coverage of test run.

    This detects whether bazel is running in coverage mode (i.e. via `bazel coverage ...`),
    and records and outputs coverage if so.

    The following environment variables are set by Bazel:

    - COVERAGE
    - COVERAGE_DIR
    - COVERAGE_MANIFEST
    - COVERAGE_OUTPUT_FILE

    """
    coverage_enabled = (os.getenv("COVERAGE") == "1")
    if not coverage_enabled:
        yield
        return
    coverage_file = Path(os.environ["COVERAGE_DIR"]) / ".coverage"
    coverage_output_file = os.environ["COVERAGE_OUTPUT_FILE"]
    coverage_sources = Path(os.environ["COVERAGE_MANIFEST"]).read_text().splitlines()
    coverage = Coverage(
        data_file=coverage_file,
        include=coverage_sources,
        branch=True,
    )
    coverage.start()
    try:
        yield
    finally:
        coverage.stop()
        coverage.save()
        coverage.lcov_report(
            outfile=coverage_output_file,
        )


if __name__ == "__main__":
    with record_coverage():
        exit_code = pytest.main(sys.argv[1:])
    sys.exit(exit_code)
