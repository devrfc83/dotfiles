#!/usr/bin/env bash
set -euo pipefail

# Instala lo que no está en packages.txt: rustup y fnm, oh-my-zsh y los plugins
# de zsh y tmux, crates de Cargo, programas de Python con pipx, programas que se
# compilan desde el upstream o desde fuentes de Debian, extensiones de los
# editores, Zed, opencode y plugins de Vim. Lo
# ejecuta fedora-install.sh al final, después de dotfiles-install.sh; requiere
# los paquetes de packages.txt (compiladores, ncurses-devel, python3-devel,
# cmake, pipx).
# Si un paso falla, se continúa con los demás y se informa al final.
# Puede ejecutarse varias veces; también sirve para actualizar.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
crates=(typst-cli genact tetris-tui)
# Programas de Python que no están en Fedora (dotfiles-update.sh los actualiza con
# pipx upgrade-all)
pipx_apps=(sqlmap)

# shellcheck source=scripts/lib/steps.sh
source "${scripts_dir}/lib/steps.sh"

step "rustup y fnm (Node.js)" bash "${scripts_dir}/install-runtimes.sh"
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
step "Tela (tema de iconos)" bash "${scripts_dir}/install-tela-icons.sh"
step "nikto" bash "${scripts_dir}/install-nikto.sh"
step "Extensiones de VSCodium y Cursor" bash "${scripts_dir}/install-editor-extensions.sh"
step "Zed" bash "${scripts_dir}/install-zed.sh"
step "opencode" bash "${scripts_dir}/install-opencode.sh"
step "Plugins de Vim y YouCompleteMe" bash "${scripts_dir}/install-vim-plugins.sh"
step "Piper (voz del saludo)" bash "${scripts_dir}/install-piper.sh"

# pipx_install <programa>: lo instala con pipx si falta
pipx_install() {
  if pipx list --short 2>/dev/null | grep -q "^$1 "; then
    echo "$1 ya está instalado."
  else
    pipx install "$1"
  fi
}
if command -v pipx >/dev/null 2>&1; then
  for app in "${pipx_apps[@]}"; do
    step "pipx: ${app}" pipx_install "${app}"
  done
else
  echo "Advertencia: no se encontró pipx (packages.txt)." >&2
  failed+=("pipx (no instalado)")
fi

steps_report "Extras instalados."
