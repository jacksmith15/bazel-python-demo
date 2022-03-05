load("//tools/pytest:defs.bzl", "pytest_test")
load("//tools/mypy:defs.bzl", "mypy_test")


def python_library(name, srcs=[], test_deps=[], imports=[], **kwargs):
    """A macro for declaring a python library, complete with tests and typechecking.

    Tests are considered anything under tests/ folder, or ending `_test.py`.
    """
    test_srcs = [src for src in srcs if src.startswith("tests/") or src.endswith("_test.py")]
    srcs = [src for src in srcs if src not in test_srcs]

    native.py_library(
        name=name,
        srcs=srcs,
        imports=imports,
        **kwargs
    )

    # We can replace deps to point at library above (existing ones become transitive):
    kwargs["deps"] = [":{}".format(name)] + test_deps

    mypy_test(
        name="{}_typecheck_srcs".format(name),
        srcs=srcs,
        imports=imports,
        **kwargs,
    )

    mypy_test(
        name="{}_typecheck_tests".format(name),
        srcs=test_srcs,
        imports=imports,
        **kwargs,
    )

    pytest_test(
        name="{}_tests".format(name),
        srcs=test_srcs,
        imports=imports,
        **kwargs,
    )
