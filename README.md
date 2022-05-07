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

To run the formatter (`black` and `isort`):

```bash
./format.sh
```

> :information_source: This doesn't happen automatically as part of `bazel build`. `bazel test` will check that the formatter has been run, but not reformat the files. This is because bazel operates on sandboxed copies of the source files, and also because formatting during a build would invalidate caching.


You can also just output the formatted diff without changing any files:

```bash
./format.sh --diff
```

## Checking test coverage

Test coverage is automatically generated when running `bazel test`, and combined into and lcov report under `bazel-out/_coverage`.

To generate an HTML coverage report, run:

```bash
./coverage.sh
```

> :information_source: This requires that [lcov](https://github.com/linux-test-project/lcov) is installed.
>   Install with e.g. `brew install lcov` or `apt install lcov`


## Docker images

If a `python_library` target has `image_repository` set, then it will build a docker image.

### Publishing

Docker images can be published using:

```bash
./publish.sh
```

You can also publish a subset of images by providing a query, for example:

```bash
./publish.sh //src/users/...
```

> :information_source: The target repository is set on the rule. The target registry and tags are controlled by [workspace status](https://docs.bazel.build/versions/main/user-manual.html#workspace_status), specifically the values provided in [stamp.sh](./stamp.sh).
> The images are published as `{STABLE_IMAGE_REGISTRY}/{repository}:{STABLE_GIT_BRANCH}-{GIT_COMMIT_DATE}-{SHORT_GIT_SHA}`.
> `STABLE_IMAGE_REGISTRY` is set to `localhost:5000` - you can create a registry on that port by following the instructions in [infra/](./infra).

### Running

You can also just run an image using:

```bash
bazel run //src/directory:image -- -p 8080:80 -- arg0 arg1
```


## TODOS

- `pydocstyle` etc.
- Test coverage doesn't support branch coverage (limitation of `lcov` format in coverage-py).
- IDE integration??? PYTHONPATH is all over the place.
    + Just use the local venv, with PYTHONPATH=src
- `PACKAGECLOUD_TOKEN` support (stamps? --define?)
- Packaging support (i.e. publishing wheels, building and publishing docker images).
- Running tests for multiple python versions?
- Maybe remote caching?
