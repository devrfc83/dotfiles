#!/usr/bin/env bash
set -euo pipefail

# DBeaver Community Edition (cliente de bases de datos: PostgreSQL, SQLite, MySQL
# y otras por JDBC) no está en Fedora: se instala el RPM de los releases del
# upstream (paquete dbeaver-ce, con su propio JRE: no depende del Java del
# sistema), en una versión fija y con su sha256 (scripts/lib/release-rpm.sh). Si
# ya está esa versión, no hace nada. Lo ejecuta extras-install.sh.
#
# Para actualizar, deben cambiarse version y sha256 (el que muestra GitHub junto a
# dbeaver-ce-<versión>-linux-x86_64.rpm); check-versions.sh avisa cuando hay una
# versión nueva.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/release-rpm.sh
source "${scripts_dir}/lib/release-rpm.sh"

version="26.2.5.2"
sha256="81fad982fb25f28989c48d994bc6d3cbfa8d51a17df768b5f7f2164905937127"
repo_url="https://github.com/dbeaver/dbeaver.git"
rpm_url="${repo_url%.git}/releases/download/${version}/dbeaver-ce-${version}-linux-x86_64.rpm"

# El RPM rompe /usr/bin/dbeaver al actualizar: el %post del paquete nuevo hace
# ln -s sin -f (falla si el enlace existe, y dnf termina con error) y después el
# %preun del viejo borra el enlace. Antes de actualizar se quita, para que el
# %post no falle, y al final se vuelve a crear si falta.
link="/usr/bin/dbeaver"
installed="$(rpm -q --qf '%{VERSION}' dbeaver-ce 2>/dev/null || true)"
if [[ -n "${installed}" && "${installed}" != "${version}" && -L "${link}" ]]; then
  sudo rm -f "${link}"
fi

install_release_rpm dbeaver-ce "${version}" "${rpm_url}" "${sha256}"

if [[ ! -e "${link}" ]]; then
  sudo ln -sfn /usr/share/dbeaver-ce/dbeaver "${link}"
  echo "Enlazado  ${link} (lo borró la actualización del RPM)"
fi
