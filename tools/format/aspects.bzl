load("@bazel_skylib//lib:shell.bzl", "shell")


VALID_RULE_TYPES = ["py_library"]#, "py_test"]


_FORMATTER_TEMPLATE = """#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Copy the source files to an output directory before formatting:
in_out_pairs=("$@")

for pair in "${{in_out_pairs[@]}}"
do
    array=(${{pair//;/ }})
    read source output <<< "${{array[*]}}"
    mkdir -p $(dirname $output)
    cp $source $output
done

# Run the linters
{black} -- {sources}
{isort} -- {sources}

"""

def _format_aspect_impl(target, ctx):
    if ctx.rule.kind not in VALID_RULE_TYPES:
        return []  # Only format valid targets
    if ctx.label.workspace_name:
        return []  # External repos
    source_files = [file for src in getattr(ctx.rule.attr, "srcs", []) for file in src.files.to_list()]
    if not source_files:
        return []  # No source files

    prefix = "__formatted_output/{}".format(ctx.label.name)

    output_files = [ctx.actions.declare_file("{}/{}".format(prefix, file.path)) for file in source_files]

    source_output_pairs = ["{};{}".format(left.path, right.path) for left, right in zip(source_files, output_files)]

    formatter = ctx.actions.declare_file("{}_formatter".format(ctx.rule.attr.name))

    ctx.actions.write(
        output=formatter,
        content=_FORMATTER_TEMPLATE.format(
            black=ctx.executable._black.path,
            isort=ctx.executable._isort.path,
            sources=" ".join([shell.quote(output.path) for output in output_files]),
        ),
        is_executable=True,
    )

    tools, manifests = ctx.resolve_tools(
        tools=[ctx.attr._black, ctx.attr._isort, ctx.attr._pyproject],
    )

    ctx.actions.run(
        outputs=output_files,
        # inputs=source_files,
        inputs=depset(
            direct=source_files, transitive=[dep.default_runfiles.files for dep in getattr(ctx.rule.attr, "deps", [])]
        ),
        executable=formatter,
        tools=tools,
        arguments=source_output_pairs,
        mnemonic="MirrorAndFormat",
        input_manifests=manifests,
    )

    return [
        DefaultInfo(files=depset(output_files)),
        OutputGroupInfo(
            report=depset(output_files),
        ),
    ]


format = aspect(
    implementation=_format_aspect_impl,
    attr_aspects=[],
    attrs={
        "_black": attr.label(
            default=Label("//tools/black:black"),
            executable=True,
            cfg="host",
        ),
        "_isort": attr.label(
            default=Label("//tools/isort:isort"),
            executable=True,
            cfg="host",
        ),
        "_pyproject": attr.label(
            allow_single_file=True,
            default=Label("//:pyproject.toml"),
        )
    }
)
