#!/usr/bin/env python3
"""Comprueba los enlaces relativos de archivos Markdown: que exista el archivo y,
si llevan #ancla, que el título exista en él (con las anclas que genera GitHub).
No revisa los enlaces externos (http, https, mailto). Lo usa scripts/lint.sh.

Uso: check-md-links.py <archivo.md>...
"""

import os
import re
import sys

LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
HEADING = re.compile(r"^#{1,6} (.*)$")


def prose_lines(path):
    """Líneas fuera de los bloques de código, sin el código en línea."""
    code = False
    with open(path, encoding="utf-8") as f:
        for number, line in enumerate(f, 1):
            if line.lstrip().startswith("```"):
                code = not code
                continue
            if not code:
                yield number, re.sub(r"`[^`]*`", "", line.rstrip("\n"))


def anchors(path):
    """Anclas de los títulos, como las genera GitHub (los repetidos llevan -1, -2...)."""
    seen = {}
    result = set()
    code = False
    with open(path, encoding="utf-8") as f:
        for line in f:
            if line.lstrip().startswith("```"):
                code = not code
                continue
            m = None if code else HEADING.match(line.rstrip("\n"))
            if not m:
                continue
            slug = re.sub(r"[^\w\- ]", "", m.group(1).strip().lower()).replace(" ", "-")
            count = seen.get(slug, 0)
            seen[slug] = count + 1
            result.add(slug if count == 0 else f"{slug}-{count}")
    return result


def main(paths):
    status = 0
    cache = {}
    for path in paths:
        for number, line in prose_lines(path):
            for target in LINK.findall(line):
                if re.match(r"^(https?|mailto):", target):
                    continue
                file_part, _, anchor = target.partition("#")
                dest = os.path.normpath(os.path.join(os.path.dirname(path), file_part)) if file_part else path
                if not os.path.exists(dest):
                    print(f"{path}:{number}: no existe {file_part}", file=sys.stderr)
                    status = 1
                elif anchor and dest.endswith(".md"):
                    if dest not in cache:
                        cache[dest] = anchors(dest)
                    if anchor not in cache[dest]:
                        print(f"{path}:{number}: no hay un título #{anchor} en {dest}", file=sys.stderr)
                        status = 1
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
