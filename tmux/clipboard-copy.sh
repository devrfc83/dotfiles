#!/usr/bin/env bash
set -euo pipefail

# Copia al portapapeles la entrada estándar (o el archivo indicado): wl-copy si
# hay sesión Wayland ($WAYLAND_DISPLAY), xclip en X11. La usan tmux y screen en
# el modo copia; también sirve en la terminal (comando | clipboard-copy).
#
# Uso: clipboard-copy [archivo]

input="${1:-/dev/stdin}"

if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
  exec wl-copy <"${input}"
fi
exec xclip -selection clipboard <"${input}"
