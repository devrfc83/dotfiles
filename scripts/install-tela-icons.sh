#!/usr/bin/env bash
set -euo pipefail

# Tema de iconos Tela (el de icon-theme en gnome/settings.dconf). No está en
# Fedora: se instala desde el upstream, en una versión fija (el commit de su tag),
# con su install.sh, en ~/.local/share/icons. Solo los colores de colors: todos
# ocupan unos 2,7 GB, uno solo unos 80 MB (claro, oscuro y normal). Si ya está
# instalada esa versión con esos colores, no hace nada. Para actualizar, deben
# cambiarse version y commit (check-versions.sh avisa) y volver a ejecutarse.
# Lo ejecuta extras-install.sh.

version="2026-07-07"
commit="4f560eccd0acc9c192f31077c2b3202422cb24fb" # tag 2026-07-07
repo_url="https://github.com/vinceliuice/Tela-icon-theme.git"
# El color de icon-theme en gnome/settings.dconf (Tela-dracula-dark: paleta Dracula)
colors=(dracula)
icons_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/icons"
version_file="${icons_dir}/.tela-icon-theme.version"

installed="${commit} ${colors[*]}"
if [[ "$(cat "${version_file}" 2>/dev/null)" == "${installed}" ]]; then
  echo "Tela ${version} (${colors[*]}) ya está instalado."
  exit 0
fi

echo "Instalando Tela ${version} (${colors[*]})..."
build_dir="$(mktemp -d)"
trap 'rm -rf "${build_dir}"' EXIT

git -C "${build_dir}" init --quiet src
git -C "${build_dir}/src" fetch --quiet --depth 1 "${repo_url}" "${commit}"
git -C "${build_dir}/src" checkout --quiet FETCH_HEAD
(cd "${build_dir}/src" && ./install.sh -d "${icons_dir}" "${colors[@]}")

echo "${installed}" >"${version_file}"
echo "Tela ${version} instalado en ${icons_dir}."
