#!/usr/bin/env bash
set -euo pipefail

# pgFormatter (pg_format) no está en Fedora; se compila desde el upstream en una
# versión fija (el commit de su tag). Requiere perl y make (packages.txt). Si ya
# está instalada esa versión, no hace nada. Para actualizar, deben cambiarse
# version y commit y volver a ejecutarse.

version="5.11"
commit="12b7750c9aff700c8df75d7643ba055e9a7d9311" # tag v5.11
repo_url="https://github.com/darold/pgFormatter.git"

if [[ "$(pg_format --version 2>/dev/null)" == "pg_format version ${version}" ]]; then
  echo "pgFormatter ${version} ya está instalado."
  exit 0
fi

echo "Instalando pgFormatter ${version}..."
build_dir="$(mktemp -d)"
trap 'rm -rf "${build_dir}"' EXIT

git -C "${build_dir}" init --quiet src
git -C "${build_dir}/src" fetch --quiet --depth 1 "${repo_url}" "${commit}"
git -C "${build_dir}/src" checkout --quiet FETCH_HEAD
cd "${build_dir}/src"
perl Makefile.PL
make
sudo make install
echo "$(pg_format --version) instalado."
