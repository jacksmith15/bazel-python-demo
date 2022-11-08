PythonInterpreterInfo = provider(
    fields=["version", "interpreter"],
)

def _interpreter_impl(ctx):
    interpreter_target = ctx.attr.interpreter
    interpreter_file = interpreter_target.files.to_list()[0]
    return [
        DefaultInfo(files=depset([interpreter_file])),
        PythonInterpreterInfo(
            version=(ctx.attr.version_major, ctx.attr.version_minor, ctx.attr.version_patch),
            interpreter=interpreter_file,
        ),
    ]

interpreter = rule(
    implementation=_interpreter_impl,
    attrs={
        "interpreter": attr.label(allow_single_file=True),
        "version_major": attr.int(),
        "version_minor": attr.int(),
        "version_patch": attr.int(),
    }
)
