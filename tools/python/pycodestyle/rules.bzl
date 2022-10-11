load("@rules_python//python:defs.bzl", "py_test")
load("@python_deps//:requirements.bzl", "requirement")


def pycodestyle_test(name, srcs, args=[], deps=[], **kwargs):
    # Create the test target:
    if requirement("pycodestyle") not in deps:
        deps = deps + [requirement("pycodestyle")]
    py_test(
        name=name,
        srcs=[
            "//tools/python/pycodestyle:pycodestyle_wrapper.py",
        ]
        + srcs,
        main="//tools/python/pycodestyle:pycodestyle_wrapper.py",
        args=[
            # Default args can go here
            "--ignore=E501,W503,E231,E203,E402",
            "--exclude=.svn,CVS,.bzr,.hg,.git,__pycache__,.tox,*_config_parser.py",
        ]
        + args
        + [
            # Required args can go here
        ]
        + ["$(location :%s)" % x for x in srcs],
        python_version="PY3",
        srcs_version="PY3",
        deps=deps,
        **kwargs,
    )
