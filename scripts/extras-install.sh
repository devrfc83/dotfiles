#!/usr/bin/env bash
set -euo pipefail

# Instala lo que no está en packages.txt: rustup y fnm, Go, Flutter (con Dart),
# el Android SDK, Android Studio, oh-my-zsh y los plugins de zsh y tmux, crates de Cargo,
# paquetes globales de Composer y de npm, programas de Python con pipx, programas
# que se compilan desde el upstream o desde fuentes de Debian, Mailpit,
# extensiones de los editores, Zed, opencode, opencode Desktop y plugins de Vim.
# Lo ejecuta fedora-install.sh al final, después de dotfiles-install.sh; requiere
# los paquetes de packages.txt (compiladores, ncurses-devel, python3-devel, cmake,
# pipx, composer, el JDK).
# Si un paso falla, se continúa con los demás y se informa al final.
# Puede ejecutarse varias veces; también sirve para actualizar.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# cargo-audit revisa Cargo.lock contra la base de avisos RustSec
crates=(cargo-audit typst-cli genact tetris-tui)
# Paquetes globales de Composer (~/.composer/vendor/bin, al final del PATH por
# zsh/zshenv; dotfiles-update.sh los actualiza con composer global update)
composer_packages=(laravel/installer)
# Paquetes globales de npm: la CLI de Bitwarden (bw). npm los instala en la
# versión de Node predeterminada de fnm, así que al cambiar de versión
# desaparecen: dotfiles-update.sh actualiza Node antes de ejecutar este script,
# que los vuelve a instalar (siempre en su última versión)
npm_packages=(@bitwarden/cli)
# CLI de Claude Code: descarga su binario en el postinstall, así que se instala con
# sus scripts; npm 11 solo los permite para el paquete nombrado
npm_packages_with_scripts=(@anthropic-ai/claude-code)
# Programas de Python que no están en Fedora (dotfiles-update.sh los actualiza con
# pipx upgrade-all): edge-tts es la voz del saludo matutino (zsh/scripts/buenos_dias.zsh)
pipx_apps=(edge-tts sqlmap)

# shellcheck source=scripts/lib/steps.sh
source "${scripts_dir}/lib/steps.sh"

step "rustup y fnm (Node.js)" bash "${scripts_dir}/install-runtimes.sh"
step "Go (gopls y delve)" bash "${scripts_dir}/install-go.sh"
step "Flutter (con Dart)" bash "${scripts_dir}/install-flutter.sh"
step "Android SDK" bash "${scripts_dir}/install-android-sdk.sh"
step "Android Studio" bash "${scripts_dir}/install-android-studio.sh"
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

# composer global require no hace nada si el paquete ya está en su última versión
if command -v composer >/dev/null 2>&1; then
  for package in "${composer_packages[@]}"; do
    step "composer: ${package}" composer global require --no-interaction "${package}"
  done
else
  echo "Advertencia: no se encontró composer (packages.txt)." >&2
  failed+=("composer (no instalado)")
fi

# fnm solo se activa en zsh; aquí se activa a mano (Node por defecto) para encontrar npm
if ! command -v npm >/dev/null 2>&1 && command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --shell bash)"
fi
# Sin scripts de instalación: ninguno de la lista los necesita (el postinstall de
# core-js, dependencia de la CLI de Bitwarden, solo imprime publicidad) y npm 11
# avisa por cada script que bloquea. Si un paquete nuevo los necesitara, debe
# permitirse por nombre con allow-scripts en node/npmrc.
if command -v npm >/dev/null 2>&1; then
  for package in "${npm_packages[@]}"; do
    step "npm: ${package}" npm install -g --ignore-scripts "${package}@latest"
  done
  for package in "${npm_packages_with_scripts[@]}"; do
    step "npm: ${package}" npm install -g --allow-scripts="${package}" "${package}@latest"
  done
else
  echo "Advertencia: no se encontró npm; falló la instalación de fnm o de Node." >&2
  failed+=("npm (sin Node)")
fi

step "pgFormatter" bash "${scripts_dir}/install-pgformatter.sh"
step "tty-clock" bash "${scripts_dir}/install-tty-clock.sh"
step "tint" bash "${scripts_dir}/install-tint.sh"
step "Genesis Plus GX (core de RetroArch)" bash "${scripts_dir}/install-genesis-plus-gx.sh"
step "Tela (tema de iconos)" bash "${scripts_dir}/install-tela-icons.sh"
step "Bibata Modern Ice (cursor)" bash "${scripts_dir}/install-bibata-cursor.sh"
step "nikto" bash "${scripts_dir}/install-nikto.sh"
step "Mailpit (correo de desarrollo)" bash "${scripts_dir}/install-mailpit.sh"
step "ngrok (túneles)" bash "${scripts_dir}/install-ngrok.sh"
step "Completados de zsh (bw, ngrok, mailpit)" bash "${scripts_dir}/install-shell-completions.sh"
step "Extensiones de VSCodium y Cursor" bash "${scripts_dir}/install-editor-extensions.sh"
step "Zed" bash "${scripts_dir}/install-zed.sh"
step "opencode" bash "${scripts_dir}/install-opencode.sh"
step "opencode Desktop" bash "${scripts_dir}/install-opencode-desktop.sh"
step "Plugins de Vim" bash "${scripts_dir}/install-vim-plugins.sh"
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
