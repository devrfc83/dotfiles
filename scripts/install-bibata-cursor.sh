#!/usr/bin/env bash
set -euo pipefail

# Tema de cursor Bibata Modern Ice (el de cursor-theme en gnome/settings.dconf).
# No está en Fedora: se descarga el tema ya compilado de los releases del
# upstream, en una versión fija y con su sha256, y se extrae en
# ~/.local/share/icons. Si ya está instalada esa versión, no hace nada.
# Lo ejecuta extras-install.sh (y, con él, dotfiles-update.sh).
#
# Para actualizar, deben cambiarse version y sha256 (el del archivo
# Bibata-Modern-Ice.tar.xz del release; el upstream no lo publica, así que se
# calcula con sha256sum); check-versions.sh avisa cuando hay una versión nueva.

version="2.0.7"
sha256="a68cae60c4dc706350e194ebc91c5fe48bc7bc9d59e119555834a2a7ee5078ef"
repo_url="https://github.com/ful1e5/Bibata_Cursor.git"
theme="Bibata-Modern-Ice"
theme_url="${repo_url%.git}/releases/download/v${version}/${theme}.tar.xz"
icons_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/icons"
version_file="${icons_dir}/.bibata-cursor.version"

if [[ "$(cat "${version_file}" 2>/dev/null)" == "${version}" && -d "${icons_dir}/${theme}" ]]; then
  echo "${theme} ${version} ya está instalado."
  exit 0
fi

echo "Instalando ${theme} ${version}..."
download_dir="$(mktemp -d)"
trap 'rm -rf "${download_dir}"' EXIT

curl --proto '=https' --tlsv1.2 -sSfL -o "${download_dir}/${theme}.tar.xz" "${theme_url}"
echo "${sha256}  ${download_dir}/${theme}.tar.xz" | sha256sum -c --quiet

# Sin restos de la versión anterior (cursores que ya no existan)
mkdir -p "${icons_dir}"
rm -rf "${icons_dir:?}/${theme}"
tar -C "${icons_dir}" -xJf "${download_dir}/${theme}.tar.xz" "${theme}"

echo "${version}" >"${version_file}"
echo "${theme} ${version} instalado en ${icons_dir}."
