"""Wrap pytest"""

load("@rules_python//python:defs.bzl", "py_test")
load("@python_deps//:requirements.bzl", "requirement")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")


def isort_test(name, srcs, args=[], pyproject="//:pyproject.toml", **kwargs):
    # Create the test target:
    py_test(
        name=name,
        srcs=[
            "//tools/isort:isort_wrapper.py",
        ]
        + srcs,
        main="//tools/isort:isort_wrapper.py",
        args=[
            # Default args can go here
        ]
        + args
        + ["--check"]
        + ["$(location :%s)" % x for x in srcs],
        python_version="PY3",
        srcs_version="PY3",
        deps=[requirement("isort")],
        data=[pyproject],
        **kwargs,
    )
