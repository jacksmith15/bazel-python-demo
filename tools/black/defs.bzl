"""Wrap pytest"""

load("@rules_python//python:defs.bzl", "py_test")
load("@python_deps//:requirements.bzl", "requirement")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")


def black_test(name, srcs, args=[], **kwargs):
    config_name = "{}_config".format(name)
    copy_file(
        name=config_name,
        src=Label("//tools/black:pyproject.toml"),
        out="pyproject.toml",
    )
    # Create the test target:
    py_test(
        name=name,
        srcs=[
            "//tools/black:black_wrapper.py",
        ]
        + srcs,
        main="//tools/black:black_wrapper.py",
        args=[
            # Default args can go here
        ]
        + args
        + ["--diff", "--check"]
        + ["$(location :%s)" % x for x in srcs],
        python_version="PY3",
        srcs_version="PY3",
        deps=[requirement("black")],
        data=[":{}".format(config_name)],
        **kwargs,
    )
