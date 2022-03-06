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

Run `pipenv install ...` as usual to add a dependency.

A single `Pipfile` and `Pipfile.lock` pair contains the full set of dependencies for the workspace. The `Pipfile.lock` is automatically parsed by Bazel (see [tools/pipenv](./tools/pipenv)), and dependencies are automatically made available to targets based on their `deps`.

There is no need to distinguish between dev and non-dev dependencies in the Pipfile - each target specifies its own dependencies, `pipenv` is simply used for convenience of transitive dependency resolution and exact locking etc.


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


## Run the formatter

This currently must be run outside of `bazel`. You can build a local virtualenv using `pipenv sync --dev` and run the formatter using

```bash
pipenv run format
```

> :information_source: Bazel will check that the formatter has been run, but not reformat the files, since bazel operates on sandboxed copies of the source files.


## TODOS

- `pydocstyle` etc.
- IDE integration??? PYTHONPATH is all over the place.
- `PACKAGECLOUD_TOKEN` support (stamps? --define?)
- Packaging support (i.e. publishing wheels, building and publishing docker images).
- Running tests for multiple python versions?
- Maybe remote caching?
