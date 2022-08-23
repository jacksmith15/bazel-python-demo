#!/usr/bin/env bash

# Publish all docker images

set -o errexit
set -o nounset
set -o pipefail

filter=${1-"//..."}
targets=$(bazel query 'attr("image", "", attr("registry", "", '$filter'))' 2> /dev/null)

echo "\nPublishing images for the following targets:\n${targets}\n"

for target in $targets
do
    bazel run $target
done


# Publish all Python wheels
targets=$(bazel query 'attr("wheel", "", '$filter')' 2> /dev/null)

echo "\nPublishing wheels for the following targets:\n${targets}\n"

for target in $targets
do
    bazel run $target
done
