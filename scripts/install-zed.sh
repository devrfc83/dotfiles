#!/usr/bin/env bash
set -euo pipefail

# Instala Zed con su instalador oficial (no está en Fedora): lo deja en
# ~/.local/zed.app, con el enlace ~/.local/bin/zed y su entrada en el menú de
# aplicaciones. Si ya está, no hace nada: Zed se actualiza solo, y el instalador
# borraría y volvería a descargar todo. Lo ejecuta extras-install.sh; los ajustes
# están en zed/settings.json.

if [[ -x "${HOME}/.local/zed.app/bin/zed" ]]; then
  echo "Zed ya está instalado (se actualiza solo)."
  exit 0
fi

curl --proto '=https' --tlsv1.2 -sSf https://zed.dev/install.sh | sh
