# shellcheck shell=bash
# Configuración de GNOME versionada en gnome/ (la comparten dotfiles-install.sh,
# que la carga, y export-gnome-settings.sh, que la vuelca al repositorio).

# archivo (en gnome/):ruta de dconf
# shellcheck disable=SC2034
gnome_dconf=(
  "dash-to-dock.dconf:/org/gnome/shell/extensions/dash-to-dock/"
  "just-perfection.dconf:/org/gnome/shell/extensions/just-perfection/"
)

# Extensiones activas (org.gnome.shell enabled-extensions), una por línea
# shellcheck disable=SC2034
gnome_extensions_file="enabled-extensions.txt"
