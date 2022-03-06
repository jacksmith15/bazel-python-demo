load("@rules_python//python:pip.bzl", "pip_parse")
load("//tools/pipenv:repositories.bzl", "pipenv_install_internal_dependencies", "all_requirements")

_REQUIREMENTS_LOCK = "requirements-lock.txt"


_BUILD_FILE_CONTENTS = """\
package(default_visibility = ["//visibility:public"])

exports_files(["{}"])
""".format(_REQUIREMENTS_LOCK)


def _pipenv_lock_impl(rctx):
    python_interpreter = _resolve_python_interpreter(rctx)

    # result = rctx.execute(
    #     [python_interpreter, "--version"]
    # )
    # fail("{}\n{}".format(result.stdout, result.stderr))

    rctx.file("BUILD.bazel", _BUILD_FILE_CONTENTS)
    # args = [
    #     python_interpreter,
    #     "pipenv_lock.py",
    #     rctx.path(rctx.attr.pipfile),
    #     rctx.path(rctx.attr.pipfile_lock),
    #     _REQUIREMENTS_LOCK,
    # ]
    result = rctx.execute(
        [python_interpreter, "-m", "tools.pipenv.pipenv_lock.pipenv_lock", rctx.path(rctx.attr.pipfile), rctx.path(rctx.attr.pipfile_lock), _REQUIREMENTS_LOCK],
        environment = {"PYTHONPATH": _construct_pypath(rctx)},
    )

    if result.return_code:
        fail("failed to generate lockfile:\n{}\n{}".format(result.stdout, result.stderr))
    return


pipenv_lock = repository_rule(
    implementation=_pipenv_lock_impl,
    attrs={
        "pipfile": attr.label(allow_single_file=True),
        "pipfile_lock": attr.label(allow_single_file=True),
        "python_interpreter": attr.string(),
        "python_interpreter_target": attr.label(
            allow_single_file=True,
        ),
        "_lock_script": attr.label(
            default="//tools/pipenv/pipenv_lock/pipenv_lock.py"
        )
    },
    doc="""Create a new repository containing a `requirements-lock.txt` generated from a Pipfile.lock.

This is used internally by `pipenv_parse`, to bridge the gap between a Pipfile and `pip_parse`.
"""
)


def pipenv_parse(
    name,
    pipfile="//:Pipfile",
    pipfile_lock="//:Pipfile.lock",
    **kwargs
):
    """Create repositories for 3rd-party Python libraries based on a Pipfile.lock.

    Has exactly the same behaviour as `pip_parse` from `@rules_python`, but accepts a pipenv lockfile.
    """
    pipenv_install_internal_dependencies()  # Ensure pipenv is installed

    lockfile_repo_name = "{}_lockfile".format(name)
    pipenv_lock(
        name=lockfile_repo_name,
        pipfile=pipfile,
        pipfile_lock=pipfile_lock,
        **{key: value for key, value in kwargs.items() if key in ("python_interpreter", "python_interpreter_target")}
    )
    pip_parse(
        name=name,
        requirements_lock="@{}//:{}".format(lockfile_repo_name, _REQUIREMENTS_LOCK),
        **kwargs,
    )


# The following helper functions are copied from:
# https://github.com/bazelbuild/rules_python/blob/884afdccded874302aa8ca0808312f87c5f2675e/python/pip_install/pip_repository.bzl#L1
# With minor modifications (e.g. BUILD.bazel vs BUILD).

def _get_python_interpreter_attr(rctx):
    """A helper function for getting the `python_interpreter` attribute or it's default
    Args:
        rctx (repository_ctx): Handle to the rule repository context.
    Returns:
        str: The attribute value or it's default
    """
    if rctx.attr.python_interpreter:
        return rctx.attr.python_interpreter

    if "win" in rctx.os.name:
        return "python.exe"
    else:
        return "python3"


def _resolve_python_interpreter(rctx):
    """Helper function to find the python interpreter from the common attributes
    Args:
        rctx: Handle to the rule repository context.
    Returns: Python interpreter path.
    """
    python_interpreter = _get_python_interpreter_attr(rctx)

    if rctx.attr.python_interpreter_target != None:
        target = rctx.attr.python_interpreter_target
        python_interpreter = rctx.path(target)
    else:
        if "/" not in python_interpreter:
            python_interpreter = rctx.which(python_interpreter)
        if not python_interpreter:
            fail("python interpreter `{}` not found in PATH".format(python_interpreter))
    return python_interpreter


def _construct_pypath(rctx):
    """Helper function to construct a PYTHONPATH.

    Contains entries for code in this repo as well as packages downloaded from //python/pip_install:repositories.bzl.
    This allows us to run python code inside repository rule implementations.
    Args:
        rctx: Handle to the repository_context.
    Returns: String of the PYTHONPATH.
    """

    # Get the root directory of these rules
    rules_root = rctx.path(Label("//:BUILD.bazel")).dirname
    # thirdparty_roots = []
    thirdparty_roots = [
        # Includes all the external dependencies from repositories.bzl
        rctx.path(Label("@" + repo + "//:BUILD.bazel")).dirname
        for repo in all_requirements
    ]
    separator = ":" if not "windows" in rctx.os.name.lower() else ";"
    pypath = separator.join([str(p) for p in [rules_root] + thirdparty_roots])
    return pypath
