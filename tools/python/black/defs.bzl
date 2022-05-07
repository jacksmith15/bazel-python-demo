"""Wrap pytest"""

load("@rules_python//python:defs.bzl", "py_test")
load("@python_deps//:requirements.bzl", "requirement")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")


def black_test(name, srcs, args=[], pyproject="//:pyproject.toml", **kwargs):
    # Create the test target:
    py_test(
        name=name,
        srcs=[
            "//tools/python/black:black_wrapper.py",
        ]
        + srcs,
        main="//tools/python/black:black_wrapper.py",
        args=[
            # Default args can go here
        ]
        + args
        + [
            "--workers=1",
            "--check",
            # Diff causes multiprocessing issues:
            # "--diff",
        ]
        + ["$(location :%s)" % x for x in srcs],
        python_version="PY3",
        srcs_version="PY3",
        deps=[requirement("black")],
        data=[pyproject],
        **kwargs,
    )
