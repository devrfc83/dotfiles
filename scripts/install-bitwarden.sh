#!/usr/bin/env bash
set -euo pipefail

# Bitwarden (gestor de contraseñas; la aplicación de escritorio, la CLI bw la
# instala extras-install.sh con npm) no está en Fedora: se instala el RPM de los
# releases del upstream (paquete bitwarden, en /opt/Bitwarden), en una versión fija
# y con su sha256 (scripts/lib/release-rpm.sh). Se usa la versión comercial (bit-,
# la misma que se descarga desde bitwarden.com); la de código abierto es oss-. Si
# ya está esa versión, no hace nada. Lo ejecuta extras-install.sh.
#
# Para actualizar, deben cambiarse version y sha256 (el que muestra GitHub junto a
# bit-Bitwarden-<versión>-x86_64.rpm, en el release desktop-v<versión>);
# check-versions.sh avisa cuando hay una versión nueva. El nombre del archivo ya
# cambió una vez (antes no llevaba prefijo): si la descarga falla, debe revisarse.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/release-rpm.sh
source "${scripts_dir}/lib/release-rpm.sh"

version="2026.11.0"
sha256="66c3be26c25b5353430722b1858e946fcfd7a2f53d3b2ca7a087319a67d51122"
repo_url="https://github.com/bitwarden/clients.git"
rpm_url="${repo_url%.git}/releases/download/desktop-v${version}/bit-Bitwarden-${version}-x86_64.rpm"

install_release_rpm bitwarden "${version}" "${rpm_url}" "${sha256}"
