#!/usr/bin/env bash
set -euo pipefail

# tint (Tetris en la terminal) no está en los repositorios de Fedora; se compila
# desde las fuentes de Debian. Requiere gcc, make y ncurses-devel (packages.txt).
#
# Como en Debian, el binario es setgid "games" para poder escribir los puntajes
# en /var/games/tint.scores. Para cambiar de versión, deben actualizarse
# tint_version y tint_sha256 (Checksums-Sha256 del .dsc en sources.debian.org).

tint_version="0.11"
tint_sha256="c0e57d77e15777885f6c65ea675ca85b7bc89da25aae72ceb81a2321b6b7734b"
tint_url="https://deb.debian.org/debian/pool/main/t/tint/tint_${tint_version}.tar.xz"

echo "Instalando tint ${tint_version} (fuentes de Debian)..."
build_dir="$(mktemp -d)"
trap 'rm -rf "${build_dir}"' EXIT

curl -sSfL -o "${build_dir}/tint.tar.xz" "${tint_url}"
echo "${tint_sha256}  ${build_dir}/tint.tar.xz" | sha256sum -c --quiet
tar -xJf "${build_dir}/tint.tar.xz" -C "${build_dir}"

cd "${build_dir}/tint"
make localstatedir=/var/games

sudo install -D -m 2755 -g games tint /usr/local/bin/tint
sudo install -D -m 644 tint.6 /usr/local/share/man/man6/tint.6
if [[ ! -f /var/games/tint.scores ]]; then
  sudo install -D -m 664 -g games tint.scores /var/games/tint.scores
fi

echo "tint ${tint_version} instalado en /usr/local/bin/tint."
