#!/usr/bin/env python3
"""Valida archivos JSONC (JSON con comentarios y comas finales), como los ajustes
de VSCodium y Cursor. Quita los comentarios // y /* */ y las comas antes de } o ]
sin tocar el contenido de las cadenas, y valida el resultado con el módulo json.
Lo usa scripts/lint.sh.

Uso: check-jsonc.py <archivo>...
"""

import json
import re
import sys


def strip_jsonc(text):
    out = []
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if c == '"':
            # Cadena: se copia entera, respetando los escapes
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            out.append(text[i:j + 1])
            i = j + 1
        elif text.startswith("//", i):
            # Comentario de línea: se conserva el salto, para no mover los números de línea
            j = text.find("\n", i)
            i = n if j == -1 else j
        elif text.startswith("/*", i):
            j = text.find("*/", i + 2)
            if j == -1:
                raise ValueError("comentario /* sin cerrar")
            # Los saltos de línea del comentario se conservan
            out.append("\n" * text.count("\n", i, j))
            i = j + 2
        else:
            out.append(c)
            i += 1
    # Comas finales. El patrón también alcanza el interior de las cadenas, pero ahí
    # solo cambia el texto, no la validez del JSON, que es lo único que se revisa.
    return re.sub(r",(\s*[}\]])", r"\1", "".join(out))


def main(paths):
    status = 0
    for path in paths:
        try:
            with open(path, encoding="utf-8") as f:
                json.loads(strip_jsonc(f.read()))
        except (ValueError, OSError) as e:
            print(f"{path}: {e}", file=sys.stderr)
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
