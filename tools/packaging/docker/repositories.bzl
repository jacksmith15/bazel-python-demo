load("@io_bazel_rules_docker//container:container.bzl", "container_pull")


BASE_IMAGES = {
    "python_base": {
        "registry": "registry.hub.docker.com/library",
        "repository": "python",
        "tag": "3.10.2-slim",
        "digest": "sha256:8ba48802ad3183440fa20dcca40969fcbdfeb40d53637834520fbcaa4822bcac",
    }
}


def image(name):
    return "@{}//image".format(name)


def repositories():
    for name, image in BASE_IMAGES.items():
        container_pull(
            name=name,
            **image,
        )

    native.register_toolchains("//tools/packaging/docker:container_python_toolchain")
    native.register_toolchains("//tools/packaging/docker:container_cc_toolchain")
    native.register_execution_platforms(
        "@local_config_platform//:host",
        "@io_bazel_rules_docker//platforms:local_container_platform",
    )
