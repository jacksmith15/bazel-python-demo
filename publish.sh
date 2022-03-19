# Publish all docker images
filter=${1-"//..."}
targets=$(bazel query 'attr("image", "", attr("registry", "", '$filter'))' 2> /dev/null)

echo "\nPublishing images for the following targets:\n${targets}\n"

for target in $targets
do
    bazel run $target
done
