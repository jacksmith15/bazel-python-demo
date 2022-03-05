# Bazel Test

## Build everything:

```
bazel build //...:all
```

## Test everything:

```
bazel test --test_output=errors //...:all
```

## Add a new dependency

Add a new python dependency:

1. Add it to the `Pipfile`
2. Run `./lock`

> :information_source: This uses pipenv to generate the `requirements-lock.txt` file which is used by Bazel.

## Adding a new Python library

All libraries live under `src`, but you can have libraries in directories under src. See [src/core/elasticsearch/](./src/core/elasticsearch/) for an example.

Add a `BUILD.bazel` file to the root directory of your library - it should look something like this:

```python
load("@python_deps//:requirements.bzl", "requirement")
load("//tools/library:defs.bzl", "python_library")


python_library(
    name="my_library",
    deps=[
        requirement("requests"),
        "//path/to/another:library"
    ],
    test_deps=[
        requirement("pytest"),
        requirement("types-requests"),
    ],
    imports=["../.."],
    visibility=["//visibility:public"],
)
```

> :memo: The `imports` argument specifies where the PYTHONPATH is relative to your library. A best practive is to ensure this is the relative path to the `src/` folder. So e.g. a library at `src/foo` would have `imports=[".."]`, whilst a library at `src/namespace/foo` would have `imports=["../.."]`, and be imported by other libraries as `from namespace import foo`.

This takes care of collecting Python sources, and creating targets for tests, typechecking etc.


## TODOS

- `pylint`, `black`, `isort` etc.
- IDE integration??? PYTHONPATH is all over the place.
- `PACKAGECLOUD_TOKEN` support
- Packaging support (i.e. publishing wheels, building and publishing docker images).
- Running tests for multiple python versions?
- Maybe remote caching?
