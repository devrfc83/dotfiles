#!/usr/bin/env bash
set -euo pipefail

# tty-clock no está en los repositorios de Fedora; se compila desde el upstream
# en un commit fijo. Requiere gcc, make y ncurses-devel (packages.txt). Si ya está
# compilado en ese commit, no hace nada. Para actualizar, debe cambiarse el commit.

commit="f2f847cf2cc2949c8a8b7779a778f366d3743474" # 2021-11-21
repo_url="https://github.com/xorg62/tty-clock.git"
version_file="/usr/local/share/tty-clock/commit"

if command -v tty-clock >/dev/null 2>&1 && [[ "$(cat "${version_file}" 2>/dev/null)" == "${commit}" ]]; then
  echo "tty-clock ya está compilado en el commit ${commit:0:7}."
  exit 0
fi

echo "Instalando tty-clock (commit ${commit:0:7})..."
build_dir="$(mktemp -d)"
trap 'rm -rf "${build_dir}"' EXIT

git -C "${build_dir}" init --quiet src
git -C "${build_dir}/src" fetch --quiet --depth 1 "${repo_url}" "${commit}"
git -C "${build_dir}/src" checkout --quiet FETCH_HEAD
make -C "${build_dir}/src"
sudo make -C "${build_dir}/src" install
sudo install -d "$(dirname "${version_file}")"
echo "${commit}" | sudo tee "${version_file}" >/dev/null
echo "tty-clock instalado en $(command -v tty-clock)."
