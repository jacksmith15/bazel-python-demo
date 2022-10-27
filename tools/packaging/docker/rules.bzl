load("@rules_python//python:defs.bzl", "py_binary")
load("@io_bazel_rules_docker//lang:image.bzl", "app_layer", "filter_layer")
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
    py_binary(
        name=binary_name,
        exec_compatible_with=["@io_bazel_rules_docker//platforms:run_in_container"],
        **kwargs,
    )

    external_deps_layer = "{}.layer.external".format(name)
    filter_layer(name=external_deps_layer, dep=binary_name, filter="@")

    deps = [external_deps_layer] + kwargs.get("deps", [])
    for idx, dep in enumerate(deps):
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
