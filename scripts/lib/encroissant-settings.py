#!/usr/bin/env python3
"""Preferencias de En Croissant: las guarda en encroissant/settings.json y las carga.

En Croissant no tiene archivo de configuración: guarda sus preferencias en el
localStorage de WebKit, una base SQLite (tabla ItemTable, con la clave en texto y
el valor en UTF-16LE). Este script la lee y la escribe directamente:

  exportar  vuelca las preferencias de la base al JSON (lo usa
            export-gnome-settings.sh)
  aplicar   escribe en la base las del JSON y deja el resto (lo usa
            dotfiles-install.sh); si En Croissant está abierto no cambia nada,
            porque al cerrarse escribiría sus valores encima

En el JSON cada valor es el valor JSON que guarda la aplicación, salvo los de
RAW_KEYS, que se guardan como texto tal cual. Las rutas dentro de $HOME se
guardan con ~. No se guardan las claves de IGNORED_KEYS (rutas que la aplicación
crea por su cuenta) ni las que empiezan con IGNORED_PREFIXES (el estado interno de
PostHog, la telemetría); sí telemetry-enabled y la marca de exclusión de PostHog.
"""

import json
import os
import sqlite3
import subprocess
import sys
from pathlib import Path

HOME = str(Path.home())
DB = Path(os.environ.get("XDG_DATA_HOME", f"{HOME}/.local/share")) / (
    "org.encroissant.app/localstorage/tauri_localhost_0.localstorage"
)
SETTINGS = Path(__file__).resolve().parents[2] / "encroissant" / "settings.json"
SCHEMA = "CREATE TABLE IF NOT EXISTS ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB NOT NULL ON CONFLICT FAIL)"

# i18next guarda el idioma como texto, no como JSON
RAW_KEYS = {"i18nextLng"}
IGNORED_KEYS = {"databases-dir", "engines-dir", "puzzles-dir"}
IGNORED_PREFIXES = ("ph_",)


def ignored(key: str) -> bool:
    return key in IGNORED_KEYS or key.startswith(IGNORED_PREFIXES)


def home_to_tilde(value):
    if isinstance(value, str) and (value == HOME or value.startswith(HOME + "/")):
        return "~" + value[len(HOME) :]
    return value


def tilde_to_home(value):
    if isinstance(value, str) and (value == "~" or value.startswith("~/")):
        return HOME + value[1:]
    return value


def exportar() -> None:
    if not DB.exists():
        sys.exit(f"Error: no existe {DB}; En Croissant no se ha abierto nunca.")
    con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    settings = {}
    for key, blob in con.execute("SELECT key, value FROM ItemTable ORDER BY key"):
        if ignored(key):
            continue
        text = blob.decode("utf-16-le") if isinstance(blob, bytes) else str(blob)
        settings[key] = text if key in RAW_KEYS else home_to_tilde(json.loads(text))
    con.close()
    SETTINGS.parent.mkdir(exist_ok=True)
    SETTINGS.write_text(json.dumps(settings, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"Exportado encroissant/settings.json ({len(settings)} preferencias)")


def aplicar() -> None:
    settings = json.loads(SETTINGS.read_text(encoding="utf-8"))
    if subprocess.run(["pgrep", "-x", "en-croissant"], capture_output=True).returncode == 0:
        print("Advertencia: En Croissant está abierto; no se cargaron sus preferencias.", file=sys.stderr)
        return
    DB.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(DB)
    con.execute("PRAGMA journal_mode=WAL")
    con.execute(SCHEMA)
    current = {key: blob for key, blob in con.execute("SELECT key, value FROM ItemTable")}
    changed = 0
    for key, value in settings.items():
        text = value if key in RAW_KEYS else json.dumps(tilde_to_home(value), ensure_ascii=False, separators=(",", ":"))
        blob = text.encode("utf-16-le")
        if current.get(key) != blob:
            con.execute("INSERT INTO ItemTable (key, value) VALUES (?, ?)", (key, blob))
            changed += 1
    con.commit()
    con.close()
    print(f"Cargado   encroissant/settings.json ({changed} cambios)")


if __name__ == "__main__":
    commands = {"exportar": exportar, "aplicar": aplicar}
    if len(sys.argv) != 2 or sys.argv[1] not in commands:
        sys.exit("Uso: encroissant-settings.py exportar | aplicar")
    commands[sys.argv[1]]()
