import argparse
from library.subpackage.submodule import get_value

def entry_point():
    parser = argparse.ArgumentParser()
    parser.add_argument("--override", type=int, default=None)
    args = parser.parse_args()
    if args.override:
        print(args.override)
        return
    print(get_value())
