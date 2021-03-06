load("@rules_python//python:defs.bzl", "py_test")
load("@python_deps//:requirements.bzl", "requirement")


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
    for req in [
        requirement("pytest"),
        requirement("coverage")
    ]:
        if req not in deps:
            deps.append(req)
    py_test(
        name=name,
        srcs=[
            "//tools/python/pytest:pytest_wrapper.py",
        ]
        + srcs,
        main="//tools/python/pytest:pytest_wrapper.py",
        args=[
            # Default args go here.
        ]
        + args
        + ["$(location :%s)" % x for x in srcs],
        python_version="PY3",
        srcs_version="PY3",
        deps=deps,
        data=[
            pyproject,
        ]
        + data,
        **kwargs,
    )
