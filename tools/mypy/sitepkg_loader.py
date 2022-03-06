"""This is a hack to make MyPy understand Bazel's third party dependencies which aren't in site-packages.

MyPy requires that PEP-561 packages (i.e. type stub libs like `types-requests`) are available in site-packages - just
adding them to MYPYPATH is not enough to detect them (because they aren't valid module names).

See https://mypy.readthedocs.io/en/stable/installed_packages.html#installed-packages

Unfortunately, this doesn't play well with Bazel, which disregards things like site-packages and just adds third party
dependencies to the PYTHONPATH.

_However_, MyPy does provide a related workaround in case you want to type-check something in another Python
installation. This is the `--python-executable` option, which can specify another Python installation. If this is
provided, then mypy runs a section of its code (`pyinfo`) with that Python instead, in a subprocess.

The file it executes is https://github.com/python/mypy/blob/5d82d5b98098ba639c517dd9dfc7273704b1e761/mypy/pyinfo.py#L1

You can see at the following link that MyPy either calls `pyinfo.getsitepackages()` directly, or runs it in a
subprocess with the specified Python executable:

https://github.com/python/mypy/blob/5d82d5b98098ba639c517dd9dfc7273704b1e761/mypy/modulefinder.py#L642-L650

What we can do instead of passing an actual Python distribution is to give it this file, and override the results!

This is nasty and I expect it could break if the implementation changes upstream - but it appears to be the only way to
make PEP-561 packages work with Bazel. An alternative (and incompatible) solution adding all the dependencies to
MYPYPATH solves the problem of in-line type hints, or stub files included in libraries, however this does not work for
`types-requests`-style packages (the error will just say the package isn't installed).

Inspired by: https://github.com/thundergolfer/bazel-mypy-integration/pull/25/files
"""
import sys
import os
from pathlib import Path

from mypy.pyinfo import getprefixes, getsitepackages


def get_extended_sitepackages():
    yield from getsitepackages()
    current = Path.cwd()
    root = current.parent
    for path in root.iterdir():
        if path == current:
            continue
        if not path.is_dir():
            continue
        for subpath in path.iterdir():
            if subpath.is_dir() and subpath.name.endswith(".dist-info"):
                yield str(path)


if __name__ == "__main__":
    if sys.argv[-1] == "getsitepackages":
        print(repr(list(get_extended_sitepackages())))
    elif sys.argv[-1] == "getprefixes":
        print(repr(getprefixes()))
    else:
        print("ERROR: incorrect argument to pyinfo.py.", file=sys.stderr)
        sys.exit(1)
