load("//tools/python/base:utils.bzl", "path")
load("//tools/python/base:library.bzl", "link_source")
load("//tools/python/base:interpreter.bzl", "PythonInterpreterInfo")

PythonEntrypointInfo = provider(
    doc="""Provider for Python entry points.""",
    fields=["entrypoint"],
)


def _python_entrypoint_impl(ctx):
    # Configure the Python interpreter:
    interpreter_info = ctx.attr.interpreter[PythonInterpreterInfo]
    interpreter_file = ctx.actions.declare_file("%s.runfiles/bin/python" % ctx.attr.name)
    ctx.actions.symlink(output=interpreter_file, target_file=interpreter_info.interpreter)

    # Configure the pyvenv config
    pyvenv_file = ctx.actions.declare_file("%s.runfiles/pyvenv.cfg" % ctx.attr.name)
    ctx.actions.write(
        output=pyvenv_file,
        content="""include-system-site-packages = false
"""
    )

    output_files = (
        [interpreter_file, pyvenv_file]
        + [
            link_source(ctx, source_file, dep=dep)
            for dep in ctx.attr.deps
            for source_file in dep.files.to_list()
            # Don't copy interpreter from other libraries
            if (PythonInterpreterInfo not in dep or source_file != dep[PythonInterpreterInfo].interpreter)
            and (not source_file.path.endswith("pyvenv.cfg"))
        ]
    )

    executable = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.write(
        output=executable,
        content="""#!/usr/bin/env sh

$(dirname $0)/{name}.runfiles/bin/python -m {entrypoint} $@
""".format(name=ctx.attr.name, entrypoint=ctx.attr.entrypoint)
    )
    return [
        DefaultInfo(
            files=depset(output_files),
            runfiles=ctx.runfiles([]),
            executable=executable,
        ),
        PythonEntrypointInfo(entrypoint=ctx.attr.entrypoint),
        PythonInterpreterInfo(version=interpreter_info.version, interpreter=interpreter_file),
    ]


python_entrypoint = rule(
    implementation=_python_entrypoint_impl,
    attrs={
        "deps": attr.label_list(),
        "entrypoint": attr.string(),
        "interpreter": attr.label(providers=[PythonInterpreterInfo]),
    },
    executable=True,
)
