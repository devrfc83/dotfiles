#!/usr/bin/env bash
set -euo pipefail

# Instala o actualiza rustup (Rust estable, con rust-analyzer) y fnm (versiones de
# Node.js; si la predeterminada no es de la versión mayor de scripts/lib/node.sh,
# instala la última de esa versión y la deja como predeterminada). fnm no está
# en Fedora: se compila con cargo, por eso va después de rustup. No modifica
# ~/.zshrc ni otros perfiles: el PATH de Cargo lo agrega zsh/zshenv y fnm se
# activa en zsh/zshrc (plugin fnm de oh-my-zsh).

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/node.sh
source "${scripts_dir}/lib/node.sh"

rustup_bin="${HOME}/.cargo/bin/rustup"
cargo_bin="${HOME}/.cargo/bin/cargo"
fnm_bin="${HOME}/.cargo/bin/fnm"

echo "── rustup ──"
if [[ -x "${rustup_bin}" ]]; then
  "${rustup_bin}" update stable
else
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
    sh -s -- -y --no-modify-path --default-toolchain stable
fi
# rust-analyzer (servidor de lenguaje para los editores) y rust-src, las fuentes
# de la biblioteca estándar que necesita para completar
"${rustup_bin}" component add rust-analyzer rust-src

echo "── fnm ──"
# cargo install solo recompila si hay una versión nueva de fnm
"${cargo_bin}" install --locked fnm

# La predeterminada debe ser de node_major (scripts/lib/node.sh): si no hay o es de
# otra versión mayor, instala la última de node_major (las demás siguen instaladas)
node_default="$("${fnm_bin}" exec --using=default node --version 2>/dev/null || true)"
if [[ "${node_default}" == "v${node_major}."* ]]; then
  echo "Node.js ${node_default} ya instalado (dotfiles-update.sh lo actualiza)."
else
  version="$(node_latest "${fnm_bin}")"
  echo "── Node.js ${version} (última de Node ${node_major}) ──"
  "${fnm_bin}" install "${version}"
  "${fnm_bin}" default "${version}"
fi
