
def _environment_impl(repository_ctx):
    variables = repository_ctx.attr.variables
    host_env = repository_ctx.os.environ

    vars_file = ""
    missing_required = []

    for key, default in variables.items():
        value = host_env.get(key, default)
        if not value and key not in host_env:
            missing_required.append(key)
            continue
        vars_file += "{key}={value}\n".format(key=key, value=repr(value))

    if missing_required:
        fail("The following required environment variables are not set:\n  - {}".format("\n  - ".join(missing_required)))

    repository_ctx.file("vars.bzl", vars_file)
    repository_ctx.file("BUILD.bazel", """
filegroup(
    name="vars",
    srcs=["vars.bzl"],
    visibility=["//visibility:public"],
)
""")


def environment(name, variables):
    rule = repository_rule(
        implementation=_environment_impl,
        attrs={
            "variables": attr.string_dict(default=variables),
        },
        environ=variables.keys(),
    )
    rule(name=name)
