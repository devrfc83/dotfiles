#!/usr/bin/env bash
set -euo pipefail

# Vuelca al repositorio (gnome/) los valores de dconf de las extensiones y la
# lista de extensiones activas. dconf es una base de datos binaria, así que no
# se enlaza: tras cambiar algo en las preferencias de una extensión, debe
# ejecutarse este script y hacer commit. dotfiles-install.sh los vuelve a cargar.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
gnome_dir="${repo_root}/gnome"

# shellcheck source=scripts/lib/gnome-dconf.sh
source "${repo_root}/scripts/lib/gnome-dconf.sh"

if ! command -v dconf >/dev/null 2>&1; then
  echo "Error: no está dconf." >&2
  exit 1
fi

mkdir -p "${gnome_dir}"

for entry in "${gnome_dconf[@]}"; do
  file="${entry%%:*}"
  dconf dump "${entry#*:}" >"${gnome_dir}/${file}"
  echo "Exportado gnome/${file}"
done

# ['a@b', 'c@d'] -> una extensión por línea
gsettings get org.gnome.shell enabled-extensions |
  tr -d "[]' " | tr ',' '\n' | sed '/^$/d' | sort >"${gnome_dir}/${gnome_extensions_file}"
echo "Exportado gnome/${gnome_extensions_file}"
