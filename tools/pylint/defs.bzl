"""Wrap pytest"""

load("@rules_python//python:defs.bzl", "py_test")
load("@python_deps//:requirements.bzl", "requirement")


def pylint_test(name, srcs, args=[], deps=[], pylintrc=None, **kwargs):
    # Create the test target:
    if pylintrc:
        args = args + ["--rcfile", "$(location {})".format(pylintrc)]
    if requirement("pylint") not in deps:
        deps = deps + [requirement("pylint")]
    py_test(
        name=name,
        srcs=[
            "//tools/pylint:pylint_wrapper.py",
        ]
        + srcs,
        main="//tools/pylint:pylint_wrapper.py",
        args=[
            # Default args can go here
        ]
        + args
        + [
            "--persistent=no",
            # Required args can go here
        ]
        + ["$(location :%s)" % x for x in srcs],
        python_version="PY3",
        srcs_version="PY3",
        deps=deps,
        data=[pylintrc],
        **kwargs,
    )
