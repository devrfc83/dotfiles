#!/usr/bin/env bash
set -euo pipefail

# Instala lo que no está en packages.txt: rustup y nvm, oh-my-zsh y los plugins
# de zsh y tmux, crates de Cargo, programas que se compilan desde el upstream o
# desde fuentes de Debian, extensiones de los editores y plugins de Vim. Debe ejecutarse después de fedora-install.sh (compiladores,
# ncurses-devel, python3-devel, cmake, pipx) y de dotfiles-install.sh.
# Si un paso falla, se continúa con los demás y se informa al final.
# Puede ejecutarse varias veces; también sirve para actualizar.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
crates=(typst-cli genact tetris-tui)
failed=()

step() {
  local name="$1"
  shift
  echo
  echo "── ${name} ──"
  if ! "$@"; then
    echo "Error en: ${name}" >&2
    failed+=("${name}")
  fi
}

step "rustup y nvm (Node.js)" bash "${scripts_dir}/install-runtimes.sh"
step "oh-my-zsh, plugins de zsh y tmux" bash "${scripts_dir}/install-shell-plugins.sh"

# rustup recién instalado: cargo todavía no está en el PATH de este script
PATH="${HOME}/.cargo/bin:${PATH}"

if command -v cargo >/dev/null 2>&1; then
  for crate in "${crates[@]}"; do
    step "cargo: ${crate}" cargo install --locked "${crate}"
  done
else
  echo "Advertencia: no se encontró cargo; falló la instalación de rustup." >&2
  failed+=("cargo (sin rustup)")
fi

step "pgFormatter" bash "${scripts_dir}/install-pgformatter.sh"
step "tty-clock" bash "${scripts_dir}/install-tty-clock.sh"
step "tint" bash "${scripts_dir}/install-tint.sh"
step "Genesis Plus GX (core de RetroArch)" bash "${scripts_dir}/install-genesis-plus-gx.sh"
step "Extensiones de VSCodium y Cursor" bash "${scripts_dir}/install-editor-extensions.sh"
step "Plugins de Vim y YouCompleteMe" bash "${scripts_dir}/install-vim-plugins.sh"
step "Piper (voz del saludo)" bash "${scripts_dir}/install-piper.sh"

echo
if ((${#failed[@]} > 0)); then
  echo "Terminado con errores en: ${failed[*]}" >&2
  exit 1
fi
echo "Extras instalados."
