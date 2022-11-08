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
    # print_vars(ctx, ignore=["aspect_ids", "build_setting_value", "rule"])
    # print_vars(ctx.label, ignore=["aspect_ids", "build_setting_value", "rule"])
    executable = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.write(
        output=executable,
        content="""#!/usr/bin/env bash

{interpreter_path} -m {entrypoint}

""".format(
            entrypoint=ctx.attr.entrypoint,
            pythonpath=path(ctx.bin_dir.path).get_child(ctx.label.package).get_child("%s.runfiles" % ctx.label.name).value,
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
)
