#!/usr/bin/env python3
"""Comprueba que los archivos solo usen colores de la paleta (scripts/lib/dracula.palette):
los #rrggbb y los códigos de 24 bits de dircolors (38;2;R;G;B y 48;2;R;G;B).
Lo usa scripts/lint.sh.

Uso: check-palette.py <paleta> <archivo>...
"""

import re
import sys

HEX = re.compile(r"#([0-9a-fA-F]{6})\b")
RGB = re.compile(r"\b[34]8;2;(\d+);(\d+);(\d+)")


def main(palette_path, paths):
    with open(palette_path, encoding="utf-8") as f:
        palette = {m.group(1).lower() for line in f if (m := re.match(r"^#([0-9a-fA-F]{6})\b", line))}
    status = 0
    for path in paths:
        with open(path, encoding="utf-8") as f:
            for number, line in enumerate(f, 1):
                found = [m.group(1).lower() for m in HEX.finditer(line)]
                found += ["%02x%02x%02x" % tuple(int(c) for c in m.groups()) for m in RGB.finditer(line)]
                for color in found:
                    if color not in palette:
                        print(f"{path}:{number}: #{color} no está en la paleta ({palette_path})", file=sys.stderr)
                        status = 1
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2:]))
