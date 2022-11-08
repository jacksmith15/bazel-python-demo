load("//tools/python/base:utils.bzl", "path", "print_vars")
load("//tools/python/base:library.bzl", "link_source")

PythonEntrypointInfo = provider(
    doc="""Provider for Python entry points.""",
    fields=["entrypoint"],
)


def _python_entrypoint_impl(ctx):
    output_files = [
        link_source(ctx, source_file, dep=dep)
        for dep in ctx.attr.deps
        for source_file in dep.files.to_list()
    ]
    executable = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.write(
        output=executable,
        content="""#!{interpreter_path}
import os
import sys
from pathlib import Path

os.environ["PYTHONPATH"] = str(Path(__file__).parent / "{name}.runfiles")
os.execv("{interpreter_path}", ["{interpreter_path}", "-m", "{entrypoint}", *sys.argv[1:]])
""".format(
            entrypoint=ctx.attr.entrypoint,
            name=ctx.attr.name,
            interpreter_path=ctx.attr.interpreter_path,
        )
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
    },
    executable=True,
)
