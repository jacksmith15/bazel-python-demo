"""Repository rules for Go

Generally extensions or customization of those found in rules_go
"""
load("@io_bazel_rules_go//go:deps.bzl", "go_download_sdk")


def go_register_toolchains(version="1.16.2"):
    """Register Go toolchains.

    rules_docker depends on an outdated version of rules_go (v0.24) whose
    auto-detect logic for architecture assumes all Maxs are amd64, which is
    not true for M!.

    Instead of relying on the auto-detect functionality, we instead download
    the SDK for each host platform we need.

    We could make this smarter with a repository rule to accurately detect.
    """
    go_download_sdk(version=version, name="go_sdk_linux_amd64", goos="linux", goarch="amd64")
    go_download_sdk(version=version, name="go_sdk_darwin_amd64", goos="darwin", goarch="amd64")
    go_download_sdk(version=version, name="go_sdk_darwin_arm64", goos="darwin", goarch="arm64")
