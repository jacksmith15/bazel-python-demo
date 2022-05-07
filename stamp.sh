#!/usr/bin/env bash

# The following are additional stamps injected into bazel builds.

echo "STABLE_IMAGE_REGISTRY localhost:5000"
echo "STABLE_PYPI_REPOSITORY http://admin:password@localhost:6006"
echo "STABLE_GIT_BRANCH $(git rev-parse --abbrev-ref HEAD | tr '[:upper:]' '[:lower:]' | tr '/' '-')"
echo "GIT_SHA $(git rev-parse --short HEAD)"
echo "GIT_SERIAL_NUMBER $(git show -s --format=%ct HEAD)"
