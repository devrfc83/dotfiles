#!/usr/bin/env bash
set -euo pipefail

# Instala o actualiza rustup (Rust estable, con rust-analyzer) y fnm (versiones de
# Node.js, con la última versión de Node si no hay una predeterminada). fnm no está
# en Fedora: se compila con cargo, por eso va después de rustup. No modifica
# ~/.zshrc ni otros perfiles: el PATH de Cargo lo agrega zsh/zshenv y fnm se
# activa en zsh/zshrc (plugin fnm de oh-my-zsh).

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

if node_default="$("${fnm_bin}" exec --using=default node --version 2>/dev/null)"; then
  echo "Node.js ${node_default} ya instalado (para actualizar: ver docs/desarrollo.md)."
else
  node_latest="$("${fnm_bin}" list-remote --latest)"
  echo "── Node.js ${node_latest} (última versión) ──"
  "${fnm_bin}" install "${node_latest}"
  "${fnm_bin}" default "${node_latest}"
fi
