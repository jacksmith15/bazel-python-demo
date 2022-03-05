"""Wrap mypy"""

load("@rules_python//python:defs.bzl", "py_test")
load("@python_deps//:requirements.bzl", "requirement")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")


def mypy_test(name, srcs, deps=[], args=[], data=[], imports=[], **kwargs):
    mypy_ini = Label("//tools/mypy:mypy.ini")
    py_test(
        name=name,
        srcs=[
            "//tools/mypy:mypy_wrapper.py",
        ]
        + srcs,
        main="//tools/mypy:mypy_wrapper.py",
        args=[
            # Default config file:
            "--config-file={}/{}".format(mypy_ini.package, mypy_ini.name),
            # The following two are required because of Bazel's path manipulation:
            "--namespace-packages",
            "--explicit-package-bases",
        ]
        + args
        + ["$(location :%s)" % x for x in srcs],
        python_version="PY3",
        srcs_version="PY3",
        deps=deps
        + [
            requirement("mypy"),
        ],
        data=[
            mypy_ini,
        ]
        + data,
        env={
            "MYPYPATH": get_mypypath(srcs, deps, imports),
        },
        imports=imports,
        **kwargs
    )


def get_mypypath(srcs, deps, imports):
    """Get the MYPYPATH so that it matches the PYTHONPATH configured by `imports`.

    We don't have access to the 'current directory', so we need to use a relative path from
    one of the src files (we can use the `location` make variable ensure it expands later).
    """
    if not imports:
        return "."
    path = get_path_from_srcs(srcs)
    result = []
    for import_ in imports:
        result.append("/".join([path, import_]))
    return ":".join(result)


def get_path_from_srcs(srcs):
    src = srcs[0]
    depth = len(src.split("/"))
    return "$(location :{})".format(src) + ("/.." * depth)
