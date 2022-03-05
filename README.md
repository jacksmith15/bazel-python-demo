# Bazel Test

Build everything:

```
bazel build //...:all
```

Add a new python dependency:

1. Add it to the `Pipfile`
2. Run `./lock`

> :information_source: This will `pipenv sync` a virtual environment, and then run `pip freeze` from that venv to populate `requirements_lock.txt`. This is in turn used by bazel.

## TODOS

- `mypy_test` doesn't construct a comprehensive MYPYPATH, and so fails for third party imports. Currently disabled via `ignore_missing_imports = True`. Probably needs an actual rule rather than macro, to expand the MYPYPATH from deps.
- `lock` doesn't work with `extras` - probably need a bespoke script to go from `Pipfile.lock` to `requirements_lock.txt
- `pylint`, `black`, `isort` etc.
- IDE integration??? PYTHONPATH is all over the place.
- `PACKAGECLOUD_TOKEN` support
- Packaging support (i.e. publishing wheels, building and publishing docker images).
- Running tests for multiple python versions?
- Maybe remote caching?
