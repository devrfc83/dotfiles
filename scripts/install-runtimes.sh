#!/usr/bin/env bash
set -euo pipefail

# Instala o actualiza rustup (Rust estable) y nvm (con la última versión de
# Node.js si no hay ninguna). No modifica ~/.zshrc ni otros perfiles: el PATH de
# Cargo lo agrega zsh/zshenv y nvm se carga en zsh/zshrc.
# Para cambiar de versión de nvm, debe actualizarse nvm_version.

nvm_version="v0.40.8"
nvm_dir="${NVM_DIR:-${HOME}/.nvm}"
rustup_bin="${HOME}/.cargo/bin/rustup"

echo "── rustup ──"
if [[ -x "${rustup_bin}" ]]; then
  "${rustup_bin}" update stable
else
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
    sh -s -- -y --no-modify-path --default-toolchain stable
fi

echo "── nvm ${nvm_version} ──"
# Instalación manual con git (la de nvm): install.sh agregaría líneas a ~/.zshrc,
# que es un enlace a este repositorio.
if [[ -d "${nvm_dir}/.git" ]]; then
  git -C "${nvm_dir}" fetch --tags --quiet
else
  git clone --quiet https://github.com/nvm-sh/nvm.git "${nvm_dir}"
fi
git -C "${nvm_dir}" -c advice.detachedHead=false checkout --quiet "${nvm_version}"

# nvm no es compatible con set -eu
set +eu
export NVM_DIR="${nvm_dir}"
# shellcheck source=/dev/null
. "${nvm_dir}/nvm.sh"
if [[ "$(nvm version default)" == "N/A" ]]; then
  echo "── Node.js (última versión) ──"
  nvm install node && nvm alias default node
  status=$?
else
  echo "Node.js $(nvm version default) ya instalado (para actualizar: nvm install node)."
  status=0
fi
set -eu
exit "${status}"
