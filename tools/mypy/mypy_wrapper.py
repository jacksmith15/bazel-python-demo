import sys
from mypy.__main__ import console_entry

if __name__ == "__main__":
    import os
    print("\n\nPYTHONPATH\n\n", "\n".join(os.getenv("PYTHONPATH").split(":")))
    print("\n\nMYPYPATH\n\n", "\n".join(os.getenv("MYPYPATH").split(":")))
    console_entry()
