load("//tools/python/base:utils.bzl", "path", "print_vars")
load("//tools/python/base:library.bzl", "link_source")

PythonEntrypointInfo = provider(
    doc="""Provider for Python entry points.""",
    fields=["entrypoint"],
)


def _python_entrypoint_impl(ctx):
    interpreter = ctx.actions.declare_file("%s.runfiles/python" % ctx.attr.name)
    ctx.actions.symlink(output=interpreter, target_file=ctx.attr.interpreter.files.to_list()[0])
    print(interpreter)
    print_vars(interpreter, ignore=["tree_relative_path"])

    output_files = [
        link_source(ctx, source_file, dep=dep)
        for dep in ctx.attr.deps
        for source_file in dep.files.to_list()
    ] + [interpreter]

    executable = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.write(
        output=executable,
        content="""#!/usr/bin/env sh

export PYTHONPATH=$(dirname $0)/{name}.runfiles

$PYTHONPATH/python -m {entrypoint} $@
""".format(name=ctx.attr.name, entrypoint=ctx.attr.entrypoint)
    )
    return [
        DefaultInfo(
            files=depset(output_files),
            runfiles=ctx.runfiles(output_files),
            executable=executable,
        ),
        PythonEntrypointInfo(entrypoint=ctx.attr.entrypoint),
    ]


python_entrypoint = rule(
    implementation=_python_entrypoint_impl,
    attrs={
        "deps": attr.label_list(),
        "entrypoint": attr.string(),
        "interpreter_path": attr.string(),
        "interpreter": attr.label(allow_single_file=True),
    },
    executable=True,
)
