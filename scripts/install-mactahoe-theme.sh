#!/usr/bin/env bash
set -euo pipefail

# Tema MacTahoe (el de gtk-theme en gnome/settings.dconf y el de la barra superior,
# con la extensión User Themes en gnome/user-theme.dconf). No está en Fedora: se
# instala desde el upstream, en una versión fija (el commit de su tag), con su
# install.sh. Solo la variante de variant: oscura y con acento morado (paleta
# Dracula, como el acento de GNOME), en ~/.local/share/themes en vez de ~/.themes.
# Con -l copia además su CSS en ~/.config/gtk-4.0, para que las aplicaciones
# libadwaita (casi todas las de GNOME) también lo usen; ahí quedan siempre en
# oscuro. El install.sh agrega también gnome-theme-switcher (~/.local/bin, con su
# .desktop): se borra, porque solo cambia de variante y la de aquí es fija.
# Requiere sassc y glib2-devel (packages.txt): si faltan, el install.sh los
# instalaría por su cuenta con dnf.
# Si ya está instalada esa versión, no hace nada. Para actualizar, deben cambiarse
# version y commit (check-versions.sh avisa) y volver a ejecutarse.
#
# Tema de GDM (pantalla de inicio de sesión), con tweaks.sh -g y sudo, con el
# fondo del escritorio (gnome/background.jpg; tweaks.sh lo desenfoca y oscurece).
# GNOME no permite cambiarle el tema a GDM: se reemplaza un archivo del paquete
# gnome-shell, /usr/share/gnome-shell/gnome-shell-theme.gresource, que cada
# actualización de gnome-shell restaura. Por eso se vuelve a aplicar si rpm -V dice
# que ese archivo es el original, o si cambiaron la versión, la variante o el
# fondo (marca en gdm_version_file). Se deshace con: sudo dnf reinstall gnome-shell
# (no con tweaks.sh -r: su respaldo no se renueva cuando gnome-shell se actualiza).
# Lo ejecuta extras-install.sh (y dotfiles-update.sh, tras dnf upgrade).

version="2026-09-10"
commit="0aa2a2ba1e07277a49dae9a3b90881c899d2afbe" # tag 2026-09-10
repo_url="https://github.com/vinceliuice/MacTahoe-gtk-theme.git"
# Genera el tema MacTahoe-Dark-purple
variant=(-c dark -t purple)
themes_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/themes"
version_file="${themes_dir}/.mactahoe-gtk-theme.version"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
gdm_background="${repo_root}/gnome/background.jpg"
gdm_resource="/usr/share/gnome-shell/gnome-shell-theme.gresource"
gdm_version_file="${themes_dir}/.mactahoe-gdm-theme.version"

if ((EUID == 0)); then
  echo "Este script debe ejecutarse como usuario normal: el tema va en ${HOME}." >&2
  exit 1
fi

installed="${commit} ${variant[*]}"
user_theme=false
[[ "$(cat "${version_file}" 2>/dev/null)" == "${installed}" ]] || user_theme=true

# GDM: solo con GDM y el fondo presentes. rpm -V informa el archivo si difiere del
# paquete (devuelve 1 cuando hay diferencias: || true por pipefail).
gdm_theme=false
if command -v gdm >/dev/null 2>&1 && [[ -f "${gdm_background}" ]] && [[ -f "${gdm_resource}" ]]; then
  gdm_installed="${installed} $(sha256sum "${gdm_background}" | cut -d ' ' -f 1)"
  gdm_modified="$(rpm -Vf "${gdm_resource}" 2>/dev/null | awk -v f="${gdm_resource}" '$NF == f' || true)"
  if [[ -z "${gdm_modified}" ]] || [[ "$(cat "${gdm_version_file}" 2>/dev/null)" != "${gdm_installed}" ]]; then
    gdm_theme=true
  fi
fi

if [[ "${user_theme}" == false && "${gdm_theme}" == false ]]; then
  echo "MacTahoe ${version} ya está instalado (también en GDM)."
  exit 0
fi

build_dir="$(mktemp -d)"
# tweaks.sh, como root, deja archivos de root en el directorio temporal
trap 'rm -rf "${build_dir}" 2>/dev/null || sudo rm -rf "${build_dir}"' EXIT

git -C "${build_dir}" init --quiet src
git -C "${build_dir}/src" fetch --quiet --depth 1 "${repo_url}" "${commit}"
git -C "${build_dir}/src" checkout --quiet FETCH_HEAD

if [[ "${user_theme}" == true ]]; then
  echo "Instalando MacTahoe ${version}..."
  mkdir -p "${themes_dir}"
  (cd "${build_dir}/src" && ./install.sh -d "${themes_dir}" "${variant[@]}" -l)
  rm -f "${HOME}/.local/bin/gnome-theme-switcher" \
    "${HOME}/.local/share/applications/org.gnome.GTK4ThemeSwitcher.desktop"
  echo "${installed}" >"${version_file}"
  echo "MacTahoe ${version} instalado en ${themes_dir}."
else
  echo "MacTahoe ${version} ya está instalado."
fi

if [[ "${gdm_theme}" == true ]]; then
  echo "Aplicando MacTahoe ${version} a GDM (reemplaza ${gdm_resource})..."
  # tweaks.sh usa la ruta del fondo sin comillas: se le pasa una copia sin espacios
  cp "${gdm_background}" "${build_dir}/background.jpg"
  (cd "${build_dir}/src" && sudo ./tweaks.sh -g -b "${build_dir}/background.jpg" "${variant[@]}")
  mkdir -p "${themes_dir}"
  echo "${gdm_installed}" >"${gdm_version_file}"
  echo "MacTahoe ${version} aplicado a GDM; se ve al cerrar la sesión o reiniciar."
fi
