load("@io_bazel_rules_docker//lang:image.bzl", "app_layer")
load("@io_bazel_rules_docker//container:push.bzl", "container_push")
load("@secrets//:vars.bzl", "IMAGE_REGISTRY")


def python_image(
    name,
    repository,
    base=None,
    entrypoint=None,
    visibility=None,
    tags=[],
    **kwargs,
):
    binary_name = "{}.binary".format(name)
    base = base or "//tools/packaging/docker:default_python_base"
    native.py_binary(
        name=binary_name,
        **kwargs,
    )
    for idx, dep in enumerate(kwargs.get("deps", [])):
        base = app_layer(
            name="{}.layer.{}".format(name, idx),
            base=base,
            dep=dep,
        )
        base = app_layer(
            name="{}.layer.{}-symlinks".format(name, idx),
            base=base,
            dep=dep,
            binary=binary_name,
        )

    app_layer(
        name=name,
        base=base,
        entrypoint=entrypoint or ["/usr/local/bin/python"],
        binary=binary_name,
        visibility=visibility,
        tags=tags,
        args=kwargs.get("args"),
        data=kwargs.get("data"),
        create_empty_workspace_dir=True,
    )

    # TODO: It would be cool to automatically generate the repository name from the target path.
    # E.g. //src/domain/target:image would go in {registry}/{workspace_name}/domain/target
    # However this is not possible from a macro, and a custom rule can't call another rule, so we
    # would need to copy and modify the `container_push` implementation to do this.
    container_push(
        name="{}.publish".format(name),
        image=name,
        format="Docker",
        registry=IMAGE_REGISTRY,
        repository=repository,
        tag="{STABLE_GIT_BRANCH}-{GIT_SERIAL_NUMBER}-{GIT_SHA}",
        stamp="@io_bazel_rules_docker//stamp:always",
    )
