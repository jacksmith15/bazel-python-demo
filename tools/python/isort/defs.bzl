"""Wrap pytest"""

load("@rules_python//python:defs.bzl", "py_test")
load("@python_deps//:requirements.bzl", "requirement")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")


def isort_test(name, srcs, args=[], deps=[], pyproject="//:pyproject.toml", **kwargs):
    # Create the test target:
    if requirement("isort") not in deps:
        deps = deps + [requirement("isort")]
    py_test(
        name=name,
        srcs=[
            "//tools/python/isort:isort_wrapper.py",
        ]
        + srcs,
        main="//tools/python/isort:isort_wrapper.py",
        args=[
            # Default args can go here
        ]
        + args
        + ["--check", "--diff"]
        + ["$(location :%s)" % x for x in srcs],
        python_version="PY3",
        srcs_version="PY3",
        deps=deps,
        data=[pyproject],
        **kwargs,
    )
