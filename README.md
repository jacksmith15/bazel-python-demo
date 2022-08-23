# Bazel Python Demo

A modern Python development set-up for Bazel. The purpose of the repo is to demonstrate the integration of a range of common Python development tools into a Bazel workflow, wrapped behind a simple but opinionated set of rules.

## Features

- Dependency management using [pipenv](https://pipenv.pypa.io/en/latest/)
- Code formatting using [black](https://github.com/psf/black) and [isort](https://pycqa.github.io/isort/)
- Linting and static analysis using [pylint](https://pylint.pycqa.org/en/latest/) and [mypy](https://mypy.readthedocs.io/en/stable/)
- Tests and code coverage using [pytest](https://docs.pytest.org/en/7.1.x/), [coveragepy](https://coverage.readthedocs.io/en/6.3.3/) and [lcov](http://ltp.sourceforge.net/coverage/lcov.php)
- Packaging and publishing Docker images and Python wheels
- Configuration via environment variables
- Succinct and opinionated macros for ease of developer use

## Set-up

Install [Bazelisk](https://github.com/bazelbuild/bazelisk).

## Configuration

The following environment variables are used to configure the build process, **but all have safe defaults for local testing**. These are:

- `PYPI_URL` - URL of the PyPi server to push wheels to.
- `PYPI_USERNAME` - username for authenticating with PyPi.
- `PYPI_PASSWORD` - password for authenticating with PyPi.
- `IMAGE_REGISTRY` - URL of the image registry to push docker images to.

> :information_source: These variables and defaults are defined in [WORKSPACE.bazel](./WORKSPACE.bazel).

## Quick demo

Leave the environment variables above as default, then run the following:

```bash
# Bring up the local PyPi server and image registry:
docker-compose -f infra/docker-compose.yml up -d

# Build everything
bazel build //...

# Publish all targets
./publish.sh
```

You can now view the published wheels at http://localhost:6006/simple and the published images at http://localhost:15000/v2/_catalog.

You can also try installing a published library with dependencies:

```bash
pip install core.api --extra-index-url=http://localhost:6006
```

## Build everything

```
bazel build //...
```

## Test everything

```
bazel test //...
```

## Add a new dependency

Run `pipenv install ...` as usual to add a dependency.

A single `Pipfile` and `Pipfile.lock` pair contains the full set of dependencies for the workspace. The `Pipfile.lock` is automatically parsed by Bazel (see [tools/pipenv](./tools/pipenv)), and dependencies are automatically made available to targets based on their `deps`.

There is no need to distinguish between dev and non-dev dependencies in the Pipfile - each target specifies its own dependency groups, `pipenv` is simply used for convenience of transitive dependency resolution and exact locking etc.


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
    imports=["../.."],  # This should always be the relative path to the src/ directory.
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

Test coverage is automatically generated when running `bazel test`, and combined into an lcov report under `bazel-out/_coverage`.

To generate an HTML coverage report, run:

```bash
./coverage.sh
```

> :information_source: This requires that [lcov](https://github.com/linux-test-project/lcov) is installed.
>   Install with e.g. `brew install lcov` or `apt install lcov`


## Packaging and publishing

Two types of published artifacts are supported - docker images and wheels.

### Docker images

If a `python_library` target has an `image_repository` set, then an image will be built - e.g.

```python
python_library(
    name="my_library",
    ...,
    image_repository="namespace/my-library",
)
```

The resulting image will be tagged as `namespace/my-library:{GIT_BRANCH}-{GIT_SERIAL_NUMBER}-{GIT_SHA}`.

> :information_source: The library must have a `__main__.py` file in its root namespace.

### Python wheels

To build a Python wheel, pass the `wheel` and `version` arguments to `python_library`, e.g.

```python
load("//tools/library:defs.bzl", "python_library", "wheel")

python_library(
    name="my_library",
    ...,
    version="0.1.0",
    wheel=wheel(
        name="my-library",
        requires=["requests"],
    )
)
```

> :memo: Unfortunately wheel requirements are not automatically inferred from the `deps` argument, and need to be specified explicitly.

### Publishing

Both kinds of artifacts can be published using:

```bash
./publish.sh
```

You can also publish a subset of targets by providing a query, for example:

```bash
./publish.sh //src/users/...
```

> :memo: The image registry and PyPi server are controlled via environment variables. The default values for this configuration will push to the local infrastructure found in [infra/](./infra).

> :memo: Authentication with image registries is controlled by the regular `DOCKER_CONFIG` variable (or its default `~/.docker/config.json`). This means users and CI can perform `docker login` commands before running the build and publish steps.

## Interpreter/IDE integration

Since Bazel runs everything in sandboxes it is difficult to get direct integration with IDEs. However it is possible to approximate this by creating a root virtual environment containing the superset of all dependencies:

1. Create a local virtual environment with the superset of dependencies installed:
  ```bash
  pipenv sync
  ```
2. Run a Python interpreter inside this virtual environment:
  ```bash
  pipenv run python
  ```
3. You should now have access to the modules under `src/`:
  ```
  >>> from core.logging import logger
  >>> from users.content_type import User
  ```

Since the virtual environment contains all of the tooling dependencies too, it should be possible to hook most IDEs up to this for the purposes of linting, code analysis etc.

### Constraints

This approach is not perfect, and there are a few drawbacks:

- The virtual environment contains all dependencies, so you may find something works in your venv but fails when built with Bazel. Usually this will be because the target in question doesn't declare explicitly depend on a package you require.
- This only works if all Python packages set their root import to the `src/` directory - otherwise the import paths will differ when built.


## TODOS

- `pydocstyle` etc.
- Test coverage doesn't support branch coverage (limitation of `lcov` format in coverage-py).
- Running tests for multiple python versions?
- Maybe remote caching? Definitely CircleCI caching at least
