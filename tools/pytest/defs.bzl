"""Wrap pytest"""

load("@rules_python//python:defs.bzl", "py_test")
load("@python_deps//:requirements.bzl", "requirement")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")


def pytest_test(
    name,
    srcs,
    pyproject="//:pyproject.toml",
    deps=[],
    args=[],
    data=[],
    **kwargs
):
    # Create the test target:
    if requirement("pytest") not in deps:
        deps.append(requirement("pytest"))
    py_test(
        name=name,
        srcs=[
            "//tools/pytest:pytest_wrapper.py",
        ]
        + srcs,
        main="//tools/pytest:pytest_wrapper.py",
        args=[
            # "--capture=no",
        ]
        + args
        + ["$(location :%s)" % x for x in srcs],
        python_version="PY3",
        srcs_version="PY3",
        deps=deps,
        data=[
            # ":{}".format(config_name),
            pyproject,
        ]
        + data,
        **kwargs,
    )
