#!/usr/bin/env bash
set -euo pipefail

# Vuelca al repositorio (gnome/) la configuración de GNOME que se versiona (la
# lista está en scripts/lib/gnome-dconf.sh): los valores de las extensiones y
# cuáles están activas, los ajustes del escritorio (settings.dconf) y el sonido
# de alerta. dconf es una base de datos binaria, así que no se enlaza: tras
# cambiar algo en Configuración o en una extensión, debe ejecutarse este script
# y hacer commit. dotfiles-install.sh los vuelve a cargar.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
gnome_dir="${repo_root}/gnome"
export LC_ALL=C

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

# Ajustes del escritorio: las ramas enteras y las claves sueltas que tienen un
# valor propio, como «sección<TAB>clave=valor»; luego se agrupan por sección, en
# orden, para que los diffs sean estables
{
  for path in "${gnome_settings_paths[@]}"; do
    # dconf dump da secciones relativas a la ruta ([/], [touchpad]): se vuelven absolutas
    dconf dump "${path}" | awk -v base="${path#/}" '
      /^\[/ {
        sub(/^\[/, ""); sub(/\]$/, "")
        section = ($0 == "/") ? base : base $0
        sub(/\/$/, "", section)
        next
      }
      /=/ { print section "\t" $0 }
    '
  done
  for key in "${gnome_settings_keys[@]}"; do
    value="$(dconf read "${key}")"
    if [[ -n "${value}" ]]; then
      dir="${key%/*}"
      printf '%s\t%s=%s\n' "${dir#/}" "${key##*/}" "${value}"
    fi
  done
} | sort -t $'\t' -k 1,1 -k 2,2 | awk -F '\t' '
  BEGIN {
    print "# Ajustes de GNOME (rutas en scripts/lib/gnome-dconf.sh). Lo genera"
    print "# scripts/export-gnome-settings.sh y lo carga dotfiles-install.sh con dconf load /."
  }
  $1 != last { print ""; print "[" $1 "]"; last = $1 }
  { sub(/^[^\t]*\t/, ""); print }
' >"${gnome_dir}/${gnome_settings_file}"
echo "Exportado gnome/${gnome_settings_file}"

# Sonido de alerta: el nombre de la alerta de GNOME a la que apunta el tema propio
# (__custom), si es el que está en uso; vacío, el sonido del tema por defecto
alert=""
alert_link="${gnome_custom_sound_dir}/bell-terminal.ogg"
if [[ "$(gsettings get org.gnome.desktop.sound theme-name)" == "'__custom'" ]] && [[ -L "${alert_link}" ]]; then
  target="$(readlink "${alert_link}")"
  if [[ "${target}" == "${gnome_alert_sounds_dir}/"*.ogg ]]; then
    alert="$(basename "${target}" .ogg)"
  fi
fi
printf '%s\n' "${alert}" | sed '/^$/d' >"${gnome_dir}/${gnome_alert_sound_file}"
echo "Exportado gnome/${gnome_alert_sound_file} (${alert:-sin alerta propia})"
