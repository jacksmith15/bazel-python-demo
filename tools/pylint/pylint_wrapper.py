import pylint


if __name__ == "__main__":
    pylint.modify_sys_path()
    pylint.run_pylint()
