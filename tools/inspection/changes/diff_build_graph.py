import json
import subprocess
import sys
from pathlib import Path


# TODO:
# - output=packages for human readable
# - output=targets for informing test runner

def main():
    targets = diff_build_graph(sys.argv[1], sys.argv[2])
    packages = subprocess.run(
        ["bazel", "query", "--output=package", " union ".join(targets)],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    print(packages)



def diff_build_graph(old_hash_file: str, new_hash_file: str) -> list[str]:
    old_hash = json.loads(Path(old_hash_file).read_text(encoding="utf-8"))
    new_hash = json.loads(Path(new_hash_file).read_text(encoding="utf-8"))
    return [key for key, value in new_hash.items() if old_hash.get(key) != value]


if __name__ == "__main__":
    main()
