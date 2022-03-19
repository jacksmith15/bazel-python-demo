#!/usr/bin/env bash

# The following are additional stamps injected into bazel builds.

echo "STABLE_IMAGE_REGISTRY localhost:5005"
echo "STABLE_GIT_BRANCH $(git rev-parse --abbrev-ref HEAD | tr '[:upper:]' '[:lower:]' | tr '/' '-')"
echo "GIT_SHA $(git rev-parse --short HEAD)"
echo "GIT_SERIAL_NUMBER $(git show -s --format=%ct HEAD)"
