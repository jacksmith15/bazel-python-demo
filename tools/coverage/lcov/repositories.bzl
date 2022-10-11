load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")


LCOV_BUILD_FILE = """\
package(default_visibility = ["//visibility:public"])

exports_files(
    ["bin/genhtml"]
)

genrule(
    name="genhtml",
    srcs=[],
    outs=["out/genhtml"],
    cmd="cp $(location bin/genhtml) $@",
    tools=["bin/genhtml"],
    executable=True,
)

"""


def install_lcov_dependencies():
    maybe(
        http_archive,
        "lcov",
        url="https://github.com/linux-test-project/lcov/releases/download/v1.16/lcov-1.16.tar.gz",
        sha256="987031ad5528c8a746d4b52b380bc1bffe412de1f2b9c2ba5224995668e3240b",
        type="tar.gz",
        build_file_content=LCOV_BUILD_FILE,
        strip_prefix="lcov-1.16",
    )
