load("@io_bazel_rules_docker//lang:image.bzl", "app_layer")


def python_image(
    name,
    base=None,
    entrypoint=None,
    visibility=None,
    tags=[],
    **kwargs,
):
    binary_name = "{}.binary".format(name)
    base = base or "//tools/docker:search_python_base"
    native.py_binary(
        name=binary_name,
        **kwargs,
    )
    # TODO: I think Python itself is getting loaded in the final layer, which may
    # explain why the final layer is 250MB :(
    # There isn't actually any need to vendor python at all, its already in the image.
    for idx, dep in enumerate(kwargs.get("deps", [])):
        base = app_layer(
            name="{}.layer.{}".format(name, idx),
            base=base,
            dep=dep,
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
