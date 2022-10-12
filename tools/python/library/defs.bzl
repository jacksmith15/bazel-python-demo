load("//tools/packaging/docker:rules.bzl", "python_image")
load("//tools/packaging/wheel:defs.bzl", "python_wheel")
load("//tools/python/black:defs.bzl", "black_test")
load("//tools/python/isort:defs.bzl", "isort_test")
load("//tools/python/mypy:defs.bzl", "mypy_test")
load("//tools/python/pylint:defs.bzl", "pylint_test")
load("//tools/python/pycodestyle:rules.bzl", "pycodestyle_test")
load("//tools/python/pydocstyle:rules.bzl", "pydocstyle_test")
load("//tools/python/pytest:defs.bzl", "pytest_test")


def python_library(
    name=None,
    srcs=None,
    data=None,
    deps=[],
    test_data=[],
    test_deps=[],
    imports=[],
    pyproject="//:pyproject.toml",
    image_repository=None,
    wheel=None,
    description=None,
    version=None,
    **kwargs
):
    """A macro for declaring a python library, complete with tests and typechecking.

    Tests are considered anything under tests/ folder, or ending `_test.py`.

    Usage:

    ```python
    load("//tools/python/library:defs.bzl", "python_library")

    python_library(
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

    The names for resulting targets are auto-generated. To create multiple in the same BUILD file,
    you can provide the `name` argument, which will be used as a prefix for target names.

    To build a docker image, either pass `image=True` or `image=kwargs`, where kwargs are passed
    directly to `python_image`.
    """
    def make_name(subname):
        prefix = "{}.".format(name) if name else ""
        return "{}{}".format(prefix, subname)

    if srcs == None:
        srcs = native.glob(["**/*.py", "**/*.pyi"])
    if data == None:
        data = native.glob(["py.typed"])

    sources = _extract_sources(srcs)

    black_test(
        name=make_name("black"),
        srcs=sources.sources + sources.test_sources,
        pyproject=pyproject,
        **kwargs,
    )

    isort_test(
        name=make_name("isort"),
        srcs=sources.sources + sources.test_sources,
        deps=deps + test_deps,
        pyproject=pyproject,
    )

    native.py_library(
        name=make_name("lib"),
        srcs=sources.sources,
        data=data + sources.stubs,
        deps=deps,
        imports=imports,
        **kwargs
    )

    if image_repository:
        if "__main__.py" not in sources.sources:
            fail("Cannot specify 'image_repository' if the sources do not include a '__main__.py' entry point.")
        python_image(
            name=make_name("image"),
            repository=image_repository,
            srcs=sources.sources,
            data=data,
            deps=deps,
            imports=imports,
            main="__main__.py",
            visibility=kwargs.get("visibility"),
        )

    if wheel:
        if not version:
            fail("Must specify a version for wheel-packaged targets.")
        python_wheel(
            name=make_name("wheel"),
            wheel_name=wheel.name,
            version=version,
            description=description,
            libs=[make_name("lib")],
            requires=wheel.requires,
            extra_requires=wheel.extra_requires,
            entry_points=wheel.entry_points,
            publish=wheel.publish,
        )

    # We can replace deps to point at library above (existing ones become transitive):
    test_deps.append(make_name("lib"))


    if sources.test_sources:
        native.py_library(  # This ensures test files are detected by formatter
            name=make_name("test"),
            srcs=sources.test_sources,
            data=test_data + sources.test_stubs,
            deps=test_deps,
            imports=imports,
            # requires=[],  # TODO: detect 3rd party requirements from deps
            **kwargs,
        )

    mypy_test(
        name=make_name("typecheck.lib"),
        srcs=sources.sources,# + sources.stubs,
        imports=imports,
        deps=test_deps,
        pyproject=pyproject,
    )

    pylint_test(
        name=make_name("pylint.lib"),
        srcs=sources.sources,
        deps=deps,
        pylintrc=Label("//tools/python/library/config:sources.pylintrc"),
        imports=imports,
    )

    pycodestyle_test(
        name=make_name("pycodestyle.lib"),
        srcs=sources.sources,
        deps=[],  # We don't other deps for pycodestyle
        imports=imports,
    )

    pydocstyle_test(
        name=make_name("pydocstyle.lib"),
        srcs=sources.sources,
        deps=[],  # We don't other deps for pydocstyle
        imports=imports,
    )

    if not sources.test_sources:
        return

    mypy_test(
        name=make_name("typecheck.tests"),
        srcs=sources.test_sources + sources.test_stubs,
        imports=imports,
        deps=test_deps,
        data=sources.test_stubs,
        pyproject=pyproject,
    )

    pylint_test(
        name=make_name("pylint.tests"),
        srcs=sources.test_sources,
        deps=test_deps,
        pylintrc=Label("//tools/python/library/config:tests.pylintrc"),
        imports=imports,
    )

    pycodestyle_test(
        name=make_name("pycodestyle.tests"),
        srcs=sources.test_sources,
        deps=[],  # We don't other deps for pycodestyle
        imports=imports,
    )

    pytest_test(
        name=make_name("pytest"),
        srcs=sources.test_sources,
        imports=imports,
        data=test_data,
        deps=test_deps,
        pyproject=pyproject,
        **kwargs,
    )


def wheel(
    name,
    requires=[],
    extra_requires={},
    entry_points={},
    publish=True,
):
    """Constructor for wheel options."""
    return struct(
        name=name,
        requires=requires,
        extra_requires=extra_requires,
        entry_points=entry_points,
        publish=publish,
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
