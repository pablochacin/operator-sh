import json
import sys
import argparse

# Parses an object and returns a list of key-value pairs.
# The key is the item's name prefixed with all its
# parents' names.
#
# This code is adapted from https://github.com/side8/k8s-operator
#
def parse(o, prefix=""):

    def flatten(lis):
        new_lis = []
        for item in lis:
            if isinstance(item, list):
                new_lis.extend(flatten(item))
            else:
                new_lis.append(item)
        return new_lis

    try:
        return {
            "str": lambda: (prefix, o),
            "int": lambda: parse(str(o), prefix=prefix),
            "float": lambda: parse(str(o), prefix=prefix),
            "bool": lambda: parse(1 if o else 0, prefix=prefix),
            "NoneType": lambda: parse("", prefix=prefix),
            "list": lambda: flatten([parse(io, f'{prefix}{"_" if prefix else ""}{ik}') for ik, io in enumerate(o)]),
            "dict": lambda: flatten([parse(io, f'{prefix}{"_" if prefix else ""}{ik}') for ik, io in o.items()]),
        }[type(o).__name__]()
    except KeyError:
        raise ValueError("type '{}' not supported".format(type(o).__name__))

def main():

    parser = argparse.ArgumentParser(description=("Transforms a json object contaning an event" \
                                     " into a list of environment variables."))
    parser.add_argument("--prefix", default="EVENT",
                        help="Prefix for environment variables")
    parser.add_argument("--no-status", action='store_true', default=False,
                       help="filter status from output")
    parser.add_argument("--no-spec", action='store_true', default=False,
                       help="filter specs from output")
    args = parser.parse_args()

    event = json.load(sys.stdin)
    prefix = args.prefix.upper()
    for (k,v) in parse(event):
        var_name = k.upper()
        if args.no_status and var_name.startswith("OBJECT_STATUS"):
            continue
        if args.no_spec and var_name.startswith("OBJECT_SPEC"):
            continue
        print(f'{prefix}_{var_name}="{v}"')

if __name__ == '__main__':
    main()
