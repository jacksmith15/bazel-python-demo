"""Wrap pytest"""

load("@rules_python//python:defs.bzl", "py_test")
load("@python_deps//:requirements.bzl", "requirement")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")


def pytest_test(name, srcs, deps=[], args=[], data=[], **kwargs):
    # Copy the config file so that pytest can discover it:
    config_name = "{}_config".format(name)
    copy_file(
        name=config_name,
        src=Label("//tools/pytest:pytest.ini"),
        out="pytest.ini",
    )
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
            ":{}".format(config_name),
        ]
        + data,
        **kwargs
    )
