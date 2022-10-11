load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")


_RULE_DEPS = [
    # The following deps are auto-generated using tools/python/pipenv/generate-pipenv-tool-deps.py
    (
        "platformdirs",
        "https://files.pythonhosted.org/packages/ed/22/967181c94c3a4063fe64e15331b4cb366bdd7dfbf46fcb8ad89650026fec/platformdirs-2.5.2-py3-none-any.whl",
        "027d8e83a2d7de06bbac4e5ef7e023c02b863d7ea5d079477e722bb41ab25788",
    ),
    (
        "pipenv",
        "https://files.pythonhosted.org/packages/b1/af/e3eb5292f0e847ae2fb0b41f1162aba0a6ad3ee0b49c01380bc05071a182/pipenv-2022.10.10-py2.py3-none-any.whl",
        "a1aebda494024328631e8e258572d4250bffc426dff0dfaa6599f138e8823f81",
    ),
    (
        "virtualenv-clone",
        "https://files.pythonhosted.org/packages/21/ac/e07058dc5a6c1b97f751d24f20d4b0ec14d735d77f4a1f78c471d6d13a43/virtualenv_clone-0.5.7-py3-none-any.whl",
        "44d5263bceed0bac3e1424d64f798095233b64def1c5689afa43dc3223caf5b0",
    ),
    (
        "distlib",
        "https://files.pythonhosted.org/packages/76/cb/6bbd2b10170ed991cf64e8c8b85e01f2fb38f95d1bc77617569e0b0b26ac/distlib-0.3.6-py2.py3-none-any.whl",
        "f35c4b692542ca110de7ef0bea44d73981caeb34ca0b9b6b2e6d7790dda8f80e",
    ),
    (
        "certifi",
        "https://files.pythonhosted.org/packages/1d/38/fa96a426e0c0e68aabc68e896584b83ad1eec779265a028e156ce509630e/certifi-2022.9.24-py3-none-any.whl",
        "90c1a32f1d68f940488354e36370f6cca89f0f106db09518524c88d6ed83f382",
    ),
    (
        "setuptools",
        "https://files.pythonhosted.org/packages/bd/b4/f120561bc94a04bae5d71ea86fe2c7d97f57ab89635b4739ec4abceda92d/setuptools-65.4.1-py3-none-any.whl",
        "1b6bdc6161661409c5f21508763dc63ab20a9ac2f8ba20029aaaa7fdb9118012",
    ),
    (
        "filelock",
        "https://files.pythonhosted.org/packages/94/b3/ff2845971788613e646e667043fdb5f128e2e540aefa09a3c55be8290d6d/filelock-3.8.0-py3-none-any.whl",
        "617eb4e5eedc82fc5f47b6d61e4d11cb837c56cb4544e39081099fa17ad109d4",
    ),
    (
        "virtualenv",
        "https://files.pythonhosted.org/packages/c1/23/9dc3c3fc959ad442397dd90cbc9ea2eca7c8a140d242c6e4222675ea9f86/virtualenv-20.16.5-py3-none-any.whl",
        "d07dfc5df5e4e0dbc92862350ad87a36ed505b978f6c39609dc489eadd5b0d27",
    ),
]

_GENERIC_WHEEL = """\
package(default_visibility = ["//visibility:public"])

load("@rules_python//python:defs.bzl", "py_library")

py_library(
    name = "lib",
    srcs = glob(["**/*.py"]),
    data = glob(["**/*"], exclude=["**/*.py", "**/* *", "BUILD", "WORKSPACE"]),
    # This makes this directory a top-level in the python import
    # search path for anything that depends on this.
    imports = ["."],
)
"""


def _repository(name):
    return "pypi_{}".format(name)


def requirement(name):
    return "@{}//:lib".format(_repository(name))


# Collate all the repository names so they can be easily consumed
all_requirements = [_repository(name) for (name, _, _) in _RULE_DEPS]


def pipenv_install_internal_dependencies():
    """
    Fetch dependencies these rules depend on. Workspaces that use the pip_install rule can call this.

    (However we call it from pip_install, making it optional for users to do so.)
    """
    for (name, url, sha256) in _RULE_DEPS:
        maybe(
            http_archive,
            "pypi_{}".format(name),
            url = url,
            sha256 = sha256,
            type = "zip",
            build_file_content = _GENERIC_WHEEL,
        )
