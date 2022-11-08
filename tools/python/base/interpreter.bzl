def _python_interpreter_impl(repository_ctx):
    result = repository_ctx.execute([repository_ctx.attr.path, "--version"])
    if not result.return_code == 0:
        fail("Couldn't detect Python version from '{path}'".format(path=repository_ctx.attr.path))
    version = result.stdout.strip().rsplit(" ", 1)[-1]
    major, minor, patch = version.split(".")

    repository_ctx.file("interpreter.bzl", """
version_str = "{version}"
version_major = {major}
version_minor = {minor}
version_patch = {patch}
version = ({major}, {minor}, {patch})

interpreter_path = "{path}"
""".format(
            version=version,
            major=major,
            minor=minor,
            patch=patch,
            path=repository_ctx.attr.path,
        )
    )

    repository_ctx.symlink(repository_ctx.attr.path, "python")

    repository_ctx.file("BUILD.bazel", """
filegroup(
    name="interpreter",
    srcs=["interpreter.bzl"],
    visibility=["//visibility:public"],
)

exports_files(["python"])

""")



python_interpreter = repository_rule(
    implementation=_python_interpreter_impl,
    attrs={
        "path": attr.string(),
    }
)
