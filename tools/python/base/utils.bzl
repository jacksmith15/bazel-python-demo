def vars(obj):
    result = {}
    for key in dir(obj):
        result[key] = getattr(obj, key, None)
    return result


def print_vars(obj, ignore=None):
    for key in dir(obj):
        if ignore and key in ignore:
            continue
        print("%s: %s" % (key, getattr(obj, key, None)))


def path(value):
    """pathlib style helper."""
    SEP = "/"  # TODO: platform-agnostic
    def parts():
        return value.strip(SEP).split(SEP)  # TODO: escapes

    def parent():
        return path(SEP.join(parts()[:-1]))

    def get_child(*relative_paths):
        rel_path_parts = []
        for rel_path in relative_paths:
            rel_path_parts.extend(path(rel_path).parts())
        result_parts = parts()
        for rel_part in rel_path_parts:
            if rel_part == ".":
                continue
            if rel_part == "..":
                result_parts.pop()
                continue
            result_parts.append(rel_part)
        return path(SEP.join(result_parts))

    def relative_to(other):
        self_parts = parts()
        other_parts = other.parts()
        for idx, part in enumerate(other_parts):
            if not self_parts[idx] == part:
                fail("%s is not a subpath of %s, %s != %s at index %s" % (value, other.value, self_parts[idx], part, idx))
        return path(SEP.join(self_parts[len(other_parts):]))


    return struct(
        value=value,
        parts=parts,
        parent=parent,
        get_child=get_child,
        relative_to=relative_to,
    )
