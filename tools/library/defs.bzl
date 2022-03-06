load("//tools/pytest:defs.bzl", "pytest_test")
load("//tools/mypy:defs.bzl", "mypy_test")
load("//tools/black:defs.bzl", "black_test")
load("//tools/isort:defs.bzl", "isort_test")


def python_library(
    name,
    srcs=None,
    data=None,
    deps=[],
    test_data=[],
    test_deps=[],
    imports=[],
    pyproject="//:pyproject.toml",
    **kwargs
):
    """A macro for declaring a python library, complete with tests and typechecking.

    Tests are considered anything under tests/ folder, or ending `_test.py`.

    Usage:

    ```
    python_library(
        name="my_library",
        srcs=glob(["**/*.py", "**/*.pyi"]), # Omit this argument for sensible default behaviour
        data=[  # If not provided, collect sensible defaults if present e.g. `py.typed`
            "py.typed",
            "words.txt",
        ],
        deps=[
            "//other/lib",
            requirement("requests"),
        ],
        test_data=glob("tests/**/fixtures/*.txt"),
        test_deps=[
            requirement("pytest"),
            requirement("types-requests"),
        ],
        imports=[".."],  # Add the parent directory to PYTHONPATH
    )
    ```
    """
    if srcs == None:
        srcs = native.glob(["**/*.py", "**/*.pyi"])
    if data == None:
        data = native.glob(["py.typed"])

    sources = _extract_sources(srcs)

    black_test(
        name="{}_black".format(name),
        srcs=sources.sources + sources.test_sources,
        pyproject=pyproject,
        **kwargs,
    )

    isort_test(
        name="{}_isort".format(name),
        srcs=sources.sources + sources.test_sources,
        pyproject=pyproject,
    )

    native.py_library(
        name=name,
        srcs=sources.sources,
        data=data + sources.stubs,
        deps=deps,
        imports=imports,
        **kwargs
    )

    # We can replace deps to point at library above (existing ones become transitive):
    test_deps.append(":{}".format(name))

    # TODO: Allow settings mypy opts and overriding mypy.ini
    mypy_test(
        name="{}_typecheck_srcs".format(name),
        srcs=sources.sources,# + sources.stubs,
        imports=imports,
        deps=test_deps,
        pyproject=pyproject,
    )

    mypy_test(
        name="{}_typecheck_tests".format(name),
        srcs=sources.test_sources + sources.test_stubs,
        imports=imports,
        deps=test_deps,
        data=sources.test_stubs,
        pyproject=pyproject,
    )

    pytest_test(
        name="{}_tests".format(name),
        srcs=sources.test_sources,
        imports=imports,
        data=test_data,
        deps=test_deps,
        pyproject=pyproject,
        **kwargs,
    )


def _extract_sources(srcs):
    sources = []
    stubs = []
    test_sources = []
    test_stubs = []

    for src in srcs:
        if _is_test(src):
            if _is_stub(src):
                test_stubs.append(src)
            else:
                test_sources.append(src)
        else:
            if _is_stub(src):
                stubs.append(src)
            else:
                sources.append(src)

    return struct(sources=sources, stubs=stubs, test_sources=test_sources, test_stubs=test_stubs)


def _is_stub(src):
    return src.endswith(".pyi")


def _is_test(src):
    return src.startswith("tests/") or _remove_extension(src).endswith("_test")


def _remove_extension(path):
    return "".join(reversed("".join(reversed(path.elems())).split(".", 1)[-1].elems()))
