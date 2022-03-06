VALID_EXTENSIONS = ["py", "pyi"]


def _mypy_test_impl(ctx):
    srcs = _extract_direct_srcs(ctx.attr.srcs)
    mypypath = _extract_mypypath(ctx.attr.imports, ctx.label)

    runfiles = _extract_runfiles(ctx)

    mypy_options = [
        # The following two flags are necessary for bazel implicit namespace package structure:
        "--namespace-packages",
        "--explicit-package-bases",
        # Config file (can be overriden via the `pyproject` attr passed to the rule)
        "--config-file={}".format(_resolve_pyproject(ctx.attr.pyproject.label)),
        # Hack to ensure third party dependency type hints are used (including PEP-561) - see `sitepkg_loader.py`:
        "--python-executable={}".format(_resolve_executable(ctx.executable._sitepkg_loader))
    ] + ctx.attr.opts  # User options

    exe = ctx.actions.declare_file("%s" % ctx.attr.name)

    ctx.actions.write(
        output=exe,
        content="""#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

export MYPYPATH="{MYPYPATH}"

{MYPY_EXE} {MYPY_OPTS} -- {MYPY_SRCS}
""".format(
            MYPYPATH=mypypath,
            MYPY_EXE=_resolve_executable(ctx.executable._mypy_cli),
            MYPY_OPTS=" ".join(mypy_options),
            MYPY_SRCS=" ".join([f.short_path for f in srcs]),
        ),
        is_executable=True,
    )
    return [DefaultInfo(executable=exe, runfiles=runfiles)]


def _extract_runfiles(ctx):
    """Extract all necessary runfiles for the rule."""
    direct_srcs = _extract_direct_srcs(ctx.attr.srcs)
    transitive_depsets = _extract_transitive_depsets(ctx)
    depset_ = depset(direct=direct_srcs, transitive=transitive_depsets)
    return ctx.runfiles(files=[file for file in depset_.to_list()])


def _extract_direct_srcs(srcs):
    """Extract srcs which have a valid extension."""
    direct_src_files = []
    for src in srcs:
        for f in src.files.to_list():
            if f.extension in VALID_EXTENSIONS:
                direct_src_files.append(f)
    return direct_src_files


def _extract_transitive_depsets(ctx):
    """Get depsets for dependencies."""
    transitive_deps = [
        ctx.attr._mypy_cli.default_runfiles.files,  # Include the mypy executable
        ctx.attr._sitepkg_loader.default_runfiles.files,  # And the site-packages loader
        ctx.attr.pyproject.files,  # And the mypy configuration file
        depset(direct=_extract_direct_srcs(ctx.attr.data)),  # Any data files (e.g. .pyi files)
    ]
    # Transitive files from any dependencies:
    for dep in ctx.attr.deps:
        transitive_deps.extend([dep.default_runfiles.files, dep.data_runfiles.files])
    return transitive_deps


def _extract_mypypath(imports, label):
    """The MYPYPATH should reflect the `imports` attr passed to the rule.

    This is similar to the behaviour for PYTHONPATH in `py_library` rules.
    """
    if not imports:
        return "."
    parts = []
    for import_ in imports:
        if import_.startswith("/"):
            print("Ignoring invalid absolute path '{}'".format(import_))
        elif import_ in ["", "."]:
            parts.append(label.package)
        else:
            parts.append("{}/{}".format(label.package, import_))
    return ":".join(parts)


def _resolve_executable(executable):
    """Resolve an executable's location relative to the root."""
    root = executable.root.path.rstrip("/") + "/"
    if executable.path.startswith(root):
        return executable.path[len(root):]
    return executable.path


def _resolve_pyproject(label):
    if label.package:
        return "{}/{}".format(label.package, label.name)
    return label.name


mypy_test = rule(
    implementation=_mypy_test_impl,
    attrs={
        "srcs": attr.label_list(allow_files=[".py"]),
        "data": attr.label_list(allow_files=True),
        "deps": attr.label_list(),
        "imports": attr.string_list(),
        "opts": attr.string_list(),
        "pyproject": attr.label(
            default=Label("//:pyproject.toml"),
            allow_single_file=True,
        ),
        "_mypy_cli": attr.label(
            default=Label("//tools/mypy:mypy"),
            executable=True,
            cfg="host",
        ),
        "_sitepkg_loader": attr.label(
            default=Label("//tools/mypy:sitepkg_loader"),
            executable=True,
            cfg="host",
        )
    },
    test=True,
)
