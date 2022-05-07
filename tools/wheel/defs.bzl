load("@rules_python//python:packaging.bzl", "py_wheel")
load("@rules_python//python:packaging.bzl", "PyWheelInfo")
load("@secrets//:vars.bzl", "PYPI_URL", "PYPI_USERNAME", "PYPI_PASSWORD")

_DEFAULT_ORG_AUTHOR = "my-org"
_DEFAULT_ORG_EMAIL = "my-team@my-org.org"


def python_wheel(
    wheel_name,
    version,
    name="wheel",
    libs=[],
    # requires=[],
    description=None,
    author=_DEFAULT_ORG_AUTHOR,
    author_email=_DEFAULT_ORG_EMAIL,
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: Implementation :: CPython",
    ],
    python_requires=">=3.10",
    stamp=0,
    strip_path_prefixes=["src/"],
    **kwargs,
):
    def make_name(subname):
        prefix = "{}.".format(name) if name else ""
        return "{}{}".format(prefix, subname)

    py_wheel(
        name=name,
        author=author,
        author_email=author_email,
        classifiers=classifiers,
        deps=libs,
        description_file=_make_description_file(make_name("description"), description),
        distribution=wheel_name,
        python_requires=python_requires,
        # requires=requires,
        stamp=stamp,
        version=version,
        strip_path_prefixes=strip_path_prefixes,
        **kwargs,
    )


def _make_description_file(name, description=None):
    if not description:
        return None
    if len(description.splitlines()) != 1:
        fail("description must be a single line")
    native.genrule(
        name=name,
        srcs=[],
        outs=["description.txt"],
        cmd="""
echo '{description}' > "$@"
""",
    )
    return name


def _wheel_publish_impl(ctx):
    """Implementation of the wheel publish rule.

    Uses twine to push a wheel to the configured PyPi server.

    The PyPi server is configured via the following environment variables on the host:

    - PYPI_URL
    - PYPI_USERNAME
    - PYPI_PASSWORD

    """
    exe = ctx.actions.declare_file("%s" % ctx.attr.name)
    twine_options = [
        "--non-interactive",
        "--skip-existing",
        "--repository-url={}".format(PYPI_URL),
        "--username={}".format(PYPI_USERNAME),
        "--password={}".format(PYPI_PASSWORD),
    ]
    ctx.actions.write(
        output=exe,
        content="""#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

{TWINE_EXE} upload {TWINE_OPTIONS} {WHEEL_DIST}

""".format(
            TWINE_EXE=_resolve_executable(ctx.executable._twine_cli),
            TWINE_OPTIONS=" ".join(twine_options),
            WHEEL_DIST=ctx.attr.wheel[PyWheelInfo].wheel.short_path,
        ),
        is_executable=True,
    )
    runfiles = ctx.runfiles(
        files=ctx.attr._twine_cli.default_runfiles.files.to_list() + ctx.attr.wheel.default_runfiles.files.to_list()
    )
    return [DefaultInfo(executable=exe, runfiles=runfiles)]


wheel_publish = rule(
    implementation=_wheel_publish_impl,
    attrs={
        "wheel": attr.label(mandatory=True, providers=[PyWheelInfo]),
        "_twine_cli": attr.label(
            default=Label("//tools/twine:twine"),
            executable=True,
            cfg="host",
        ),
        "stamp": attr.bool(default=True),
    },
    executable=True,
)


def _resolve_executable(executable):
    """Resolve an executable's location relative to the root."""
    root = executable.root.path.rstrip("/") + "/"
    if executable.path.startswith(root):
        return executable.path[len(root) :]
    return executable.path
