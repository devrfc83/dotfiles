#!/usr/bin/env bash
set -euo pipefail

# nikto (revisión de servidores web propios) no está en Fedora: se instala desde
# el upstream en una versión fija (el commit de su tag), en ~/.local/share/nikto,
# con un enlace en ~/.local/bin/nikto. Sus módulos de Perl están en packages.txt.
# La base de datos de nikto solo puede distribuirse con el paquete oficial, así
# que no se copia al repositorio: se baja del upstream. Si ya está instalada esa
# versión, no hace nada. Para actualizar, deben cambiarse version y commit
# (check-versions.sh avisa) y volver a ejecutarse. Lo ejecuta extras-install.sh.

version="2.6.1"
commit="d201dac320fc5187eac75e723dd07a716196ec5a" # tag 2.6.1
repo_url="https://github.com/sullo/nikto.git"
install_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/nikto"
bin_link="${HOME}/.local/bin/nikto"

# nikto.pl ubica sus plugins y su configuración con FindBin::RealBin, que sigue
# el enlace hasta program/
link_bin() {
  mkdir -p "$(dirname "${bin_link}")"
  ln -sfn "${install_dir}/program/nikto.pl" "${bin_link}"
}

if [[ "$(git -C "${install_dir}" rev-parse HEAD 2>/dev/null)" == "${commit}" ]]; then
  link_bin
  echo "nikto ${version} ya está instalado."
  exit 0
fi

echo "Instalando nikto ${version}..."
if [[ ! -d "${install_dir}/.git" ]]; then
  git init --quiet "${install_dir}"
fi
git -C "${install_dir}" fetch --quiet --depth 1 "${repo_url}" "${commit}"
git -C "${install_dir}" checkout --quiet --force FETCH_HEAD
link_bin
echo "nikto ${version} instalado en ${install_dir} (orden: nikto)."
