#!/usr/bin/env bash
set -euo pipefail

# Bruno (cliente de API REST y GraphQL; guarda las colecciones como archivos de
# texto, para versionarlas con git) no está en Fedora: se instala el RPM de los
# releases del upstream (paquete bruno, en /opt/Bruno), en una versión fija y con
# su sha256 (scripts/lib/release-rpm.sh). Si ya está esa versión, no hace nada.
# Lo ejecuta extras-install.sh.
#
# Para actualizar, deben cambiarse version y sha256 (el que muestra GitHub junto a
# bruno_<versión>_x86_64_linux.rpm); check-versions.sh avisa cuando hay una
# versión nueva.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/release-rpm.sh
source "${scripts_dir}/lib/release-rpm.sh"

version="4.4.0"
sha256="c14be089d7eb6f297621b0e6940b887d2adaeba9b5dcb1f0b70173462a5779d4"
repo_url="https://github.com/usebruno/bruno.git"
rpm_url="${repo_url%.git}/releases/download/v${version}/bruno_${version}_x86_64_linux.rpm"

install_release_rpm bruno "${version}" "${rpm_url}" "${sha256}"
