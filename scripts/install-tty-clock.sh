#!/usr/bin/env bash
set -euo pipefail

# tty-clock no está en los repositorios de Fedora; se compila desde el upstream.
# Requiere gcc, make y ncurses-devel (packages.txt). Sirve también para actualizar.

echo "Instalando tty-clock..."
build_dir="$(mktemp -d)"
trap 'rm -rf "${build_dir}"' EXIT

git clone --depth 1 https://github.com/xorg62/tty-clock.git "${build_dir}/tty-clock"
cd "${build_dir}/tty-clock"
make
sudo make install
echo "tty-clock instalado en $(command -v tty-clock)."
