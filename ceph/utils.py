import re

size_pattern=re.compile(r"(/d+)([TtGgMmKk]?)")
transfer_funcs = {
    'T': lambda x: int(x) << 40,
    'G': lambda x: int(x) << 30,
    'M': lambda x: int(x) << 20,
    'K': lambda x: int(x) << 10,
    '' : lambda x: int(x)
}
def norminalize_size(size):
    obj = size_pattern.match(size).groups()
    ret = transfer_funcs[obj[1].upper()](obj[0])
    return ret