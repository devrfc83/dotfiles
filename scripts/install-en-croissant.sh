#!/usr/bin/env bash
set -euo pipefail

# En Croissant (interfaz de ajedrez: análisis con motores como Stockfish, que
# descarga desde la propia aplicación, bases de partidas y repertorios) no está
# en Fedora: se instala el RPM de los releases del upstream (paquete
# en-croissant), en una versión fija y con su sha256 (scripts/lib/release-rpm.sh).
# Si ya está esa versión, no hace nada. Lo ejecuta extras-install.sh.
#
# Para actualizar, deben cambiarse version y sha256 (el que muestra GitHub junto a
# en-croissant-<versión>-1.x86_64.rpm); check-versions.sh avisa cuando hay una
# versión nueva.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/release-rpm.sh
source "${scripts_dir}/lib/release-rpm.sh"

version="0.16.1"
sha256="ebbb0694dcdc8447a1b1d0c4e9e5687c2408a12f33e5914d261d8270eeaec503"
repo_url="https://github.com/franciscoBSalgueiro/en-croissant.git"
rpm_url="${repo_url%.git}/releases/download/v${version}/en-croissant-${version}-1.x86_64.rpm"

install_release_rpm en-croissant "${version}" "${rpm_url}" "${sha256}"
