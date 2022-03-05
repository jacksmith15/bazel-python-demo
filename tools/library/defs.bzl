load("//tools/pytest:defs.bzl", "pytest_test")
load("//tools/mypy:defs.bzl", "mypy_test")


def python_library(name, srcs=[], test_deps=[], imports=[], **kwargs):
    """A macro for declaring a python library, complete with tests and typechecking.

    Tests are considered anything under tests/ folder, or ending `_test.py`.
    """
    test_srcs = [src for src in srcs if src.startswith("tests/") or src.endswith("_test.py")]
    srcs = [src for src in srcs if src not in test_srcs]

    test_imports = imports
    if "." not in test_imports or "" not in test_imports:
        test_imports = test_imports + ["."]

    native.py_library(
        name=name,
        srcs=srcs,
        imports=imports,
        **kwargs
    )

    # We can replace deps to point at library above (existing ones become transitive):
    kwargs["deps"] = [":{}".format(name)]

    mypy_test(
        name="{}_typecheck_srcs".format(name),
        srcs=srcs,
        imports=imports,
        **kwargs,
    )

    kwargs["deps"].extend(test_deps)
    mypy_test(
        name="{}_typecheck_tests".format(name),
        srcs=test_srcs,
        imports=test_imports,
        # This is necessary because multiple routes to the path are available. We could avoid it by ensuring test
        # helpers are imported as:
        #   from path.to.library.tests import helper
        # Which seems perhaps like a good idea.
        args=["--follow-imports=skip"],
        **kwargs,
    )

    pytest_test(
        name="{}_tests".format(name),
        srcs=test_srcs,
        imports=test_imports,
        **kwargs,
    )
