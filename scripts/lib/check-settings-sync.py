#!/usr/bin/env python3
"""Comprueba que dos archivos de ajustes JSONC (los de VSCodium y Cursor) tengan
las mismas claves de primer nivel con los mismos valores, salvo las propias de
cada editor: una clave que esté solo en uno de los dos debe calzar con alguno de
los patrones (fnmatch, o el nombre exacto) de --solo-a o --solo-b. Así, un
ajuste agregado en un archivo y olvidado en el otro detiene el lint.
Lo usa scripts/lint.sh.

Uso: check-settings-sync.py <a.json> <b.json> [--solo-a PATRÓN...] [--solo-b PATRÓN...]
"""

import argparse
import fnmatch
import importlib
import json
import os
import sys

# Con python3 -I el directorio del script no está en sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
strip_jsonc = importlib.import_module("check-jsonc").strip_jsonc


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.loads(strip_jsonc(f.read()))


def allowed(key, patterns):
    return any(key == p or fnmatch.fnmatchcase(key, p) for p in patterns)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("a")
    parser.add_argument("b")
    parser.add_argument("--solo-a", nargs="*", default=[], metavar="PATRÓN",
                        help="claves que solo deben estar en el primer archivo")
    parser.add_argument("--solo-b", nargs="*", default=[], metavar="PATRÓN",
                        help="claves que solo deben estar en el segundo archivo")
    args = parser.parse_args()

    a, b = load(args.a), load(args.b)
    status = 0
    for key in sorted(set(a) | set(b)):
        if key in a and key in b:
            if a[key] != b[key]:
                print(f"{args.b}: {key} = {json.dumps(b[key])}, pero en {args.a} es {json.dumps(a[key])}",
                      file=sys.stderr)
                status = 1
        elif key in a and not allowed(key, args.solo_a):
            print(f"{args.b}: falta {key} (está en {args.a})", file=sys.stderr)
            status = 1
        elif key in b and not allowed(key, args.solo_b):
            print(f"{args.a}: falta {key} (está en {args.b})", file=sys.stderr)
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main())
