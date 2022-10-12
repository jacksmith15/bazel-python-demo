load("@rules_python//python:defs.bzl", "py_test")
load("@python_deps//:requirements.bzl", "requirement")


def pydocstyle_test(name, srcs, args=[], deps=[], pyproject="//:pyproject.toml", **kwargs):
    # Create the test target:
    for dep in [
        requirement("pydocstyle"),
        requirement("toml"),  # TOML is an optional requirement for parsing pyproject config.
    ]:
        if dep not in deps:
            deps.append(dep)
    py_test(
        name=name,
        srcs=[
            "//tools/python/pydocstyle:pydocstyle_wrapper.py",
        ]
        + srcs,
        main="//tools/python/pydocstyle:pydocstyle_wrapper.py",
        args=[
            # Default args can go here
        ]
        + args
        + [
            # Required args can go here
            "--config=$(location {})".format(pyproject),
        ]
        + ["$(location :%s)" % x for x in srcs],
        python_version="PY3",
        srcs_version="PY3",
        deps=deps,
        data=[pyproject],
        **kwargs,
    )
