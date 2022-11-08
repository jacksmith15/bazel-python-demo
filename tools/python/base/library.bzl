load("//tools/python/base:utils.bzl", "path")

PythonInfo = provider(
    doc="""Provider for python packages.""",
    fields=["import_path"],
)


def _python_library_impl(ctx):
    output_files = (
        [link_source(ctx, source_file) for source_file in ctx.files.srcs]
        + [link_source(ctx, source_file) for source_file in ctx.files.data]
        + [
            link_source(ctx, source_file, dep=dep)
            for dep in ctx.attr.deps
            for source_file in dep.files.to_list()
        ]
    )
    return [
        DefaultInfo(files=depset(output_files), runfiles=ctx.runfiles(output_files), executable=None),
        PythonInfo(import_path=ctx.attr.import_path),
    ]


python_library = rule(
    implementation=_python_library_impl,
    attrs={
        "srcs": attr.label_list(allow_files=[".py"]),
        "data": attr.label_list(allow_files=True),
        "deps": attr.label_list(),
        "import_path": attr.string(),
    },
)


def link_source(ctx, source_file, dep=None):
    target_path = _get_target_path(ctx, source_file, dep=dep)
    output_file = ctx.actions.declare_file(target_path)
    ctx.actions.symlink(
        output=output_file,
        target_file=source_file,
    )
    return output_file


def _get_target_path(ctx, source_file, dep=None):
    namespace = path("%s.runfiles" % ctx.attr.name)

    if dep:
        path_prefix = path(ctx.bin_dir.path).get_child(dep.label.package).get_child("%s.runfiles" % dep.label.name)
    else:
        package_path = path(ctx.label.package)
        path_prefix = package_path.get_child(ctx.attr.import_path)

    relative_path = path(source_file.path).relative_to(path_prefix).value

    return namespace.get_child(relative_path).value
