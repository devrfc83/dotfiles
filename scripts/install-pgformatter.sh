#!/usr/bin/env bash
set -euo pipefail

echo "Instalando pgFormatter..."
build_dir="$(mktemp -d)"
trap 'rm -rf "${build_dir}"' EXIT

git clone --depth 1 https://github.com/darold/pgFormatter.git "${build_dir}/pgFormatter"
cd "${build_dir}/pgFormatter"
perl Makefile.PL
make
sudo make install
echo "$(pg_format --version) instalado."
