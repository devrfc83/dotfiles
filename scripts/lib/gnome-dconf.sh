# shellcheck shell=bash
# Configuración de GNOME versionada en gnome/ (la comparten dotfiles-install.sh,
# que la carga, y export-gnome-settings.sh, que la vuelca al repositorio).
#
# dconf solo guarda los valores distintos del predeterminado, así que los
# archivos contienen solo lo que se cambió. No se vuelcan ramas enteras como
# /org/gnome/desktop/interface/: mezclan preferencias con estado de la máquina
# (tamaños de ventana, carpetas recientes, marcas de tiempo) y hasta las
# coordenadas de la luz nocturna, que no deben ir a un repositorio público.

# Extensiones: archivo (en gnome/):ruta de dconf, una rama entera por archivo
# shellcheck disable=SC2034
gnome_dconf=(
  "appindicator.dconf:/org/gnome/shell/extensions/appindicator/"
  "dash-to-dock.dconf:/org/gnome/shell/extensions/dash-to-dock/"
  "just-perfection.dconf:/org/gnome/shell/extensions/just-perfection/"
)

# Extensiones activas (org.gnome.shell enabled-extensions), una por línea
# shellcheck disable=SC2034
gnome_extensions_file="enabled-extensions.txt"

# Ajustes del escritorio, todos en un archivo con rutas absolutas (se carga con
# dconf load /)
# shellcheck disable=SC2034
gnome_settings_file="settings.dconf"

# Ramas que solo contienen preferencias: se vuelcan enteras
# shellcheck disable=SC2034
gnome_settings_paths=(
  # Atajos de teclado: ventanas, shell, mutter y los personalizados (media-keys)
  /org/gnome/desktop/wm/keybindings/
  /org/gnome/shell/keybindings/
  /org/gnome/mutter/keybindings/
  /org/gnome/mutter/wayland/keybindings/
  /org/gnome/settings-daemon/plugins/media-keys/
  # Touchpad, ratón y teclado (repetición)
  /org/gnome/desktop/peripherals/
  # Botones y acciones de la barra de título, cantidad de espacios de trabajo
  /org/gnome/desktop/wm/preferences/
  # Archivos recientes, papelera y reporte de problemas
  /org/gnome/desktop/privacy/
  # Bienestar: recordatorios de pausas y límite de tiempo de pantalla
  /org/gnome/desktop/break-reminders/
  /org/gnome/desktop/screen-time-limits/
  # Proveedores de búsqueda de la vista de actividades
  /org/gnome/desktop/search-providers/
)

# Claves sueltas de ramas que también guardan estado
# shellcheck disable=SC2034
gnome_settings_keys=(
  # Apariencia y reloj (la fuente monoespaciada la fija dotfiles-install.sh)
  /org/gnome/desktop/interface/accent-color
  /org/gnome/desktop/interface/color-scheme
  /org/gnome/desktop/interface/icon-theme
  /org/gnome/desktop/interface/font-name
  /org/gnome/desktop/interface/document-font-name
  /org/gnome/desktop/interface/font-antialiasing
  /org/gnome/desktop/interface/font-hinting
  /org/gnome/desktop/interface/enable-animations
  /org/gnome/desktop/interface/enable-hot-corners
  /org/gnome/desktop/interface/gtk-enable-primary-paste
  /org/gnome/desktop/interface/show-battery-percentage
  /org/gnome/desktop/interface/clock-format
  /org/gnome/desktop/interface/clock-show-date
  /org/gnome/desktop/interface/clock-show-seconds
  /org/gnome/desktop/interface/clock-show-weekday
  /org/gnome/desktop/calendar/show-weekdate
  /org/gnome/desktop/datetime/automatic-timezone
  # Distribución del teclado y opciones de XKB (Compose, Caps Lock...)
  /org/gnome/desktop/input-sources/sources
  /org/gnome/desktop/input-sources/xkb-options
  # Pantalla en blanco, bloqueo y notificaciones
  /org/gnome/desktop/session/idle-delay
  /org/gnome/desktop/screensaver/lock-enabled
  /org/gnome/desktop/screensaver/lock-delay
  /org/gnome/desktop/notifications/show-banners
  /org/gnome/desktop/notifications/show-in-lock-screen
  /org/gnome/desktop/sound/event-sounds
  # Ventanas y espacios de trabajo
  /org/gnome/mutter/center-new-windows
  /org/gnome/mutter/dynamic-workspaces
  /org/gnome/mutter/edge-tiling
  /org/gnome/mutter/experimental-features
  /org/gnome/mutter/workspaces-only-on-primary
  # Luz nocturna (sin night-light-last-coordinates: es la ubicación del equipo)
  /org/gnome/settings-daemon/plugins/color/night-light-enabled
  /org/gnome/settings-daemon/plugins/color/night-light-temperature
  /org/gnome/settings-daemon/plugins/color/night-light-schedule-automatic
  /org/gnome/settings-daemon/plugins/color/night-light-schedule-from
  /org/gnome/settings-daemon/plugins/color/night-light-schedule-to
  # Energía
  /org/gnome/settings-daemon/plugins/power/idle-dim
  /org/gnome/settings-daemon/plugins/power/power-button-action
  /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type
  /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-timeout
  /org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-type
  /org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-timeout
  # Aplicaciones favoritas del dock
  /org/gnome/shell/favorite-apps
  # Servicios de ubicación
  /org/gnome/system/location/enabled
  # Archivos (Nautilus) y el selector de archivos de GTK 4
  /org/gnome/nautilus/preferences/default-folder-viewer
  /org/gnome/nautilus/preferences/default-sort-order
  /org/gnome/nautilus/preferences/default-sort-in-reverse-order
  /org/gnome/nautilus/preferences/click-policy
  /org/gnome/nautilus/preferences/recursive-search
  /org/gnome/nautilus/preferences/show-create-link
  /org/gnome/nautilus/preferences/show-delete-permanently
  /org/gnome/nautilus/preferences/show-image-thumbnails
  /org/gtk/gtk4/settings/file-chooser/show-hidden
  /org/gtk/gtk4/settings/file-chooser/sort-directories-first
  /org/gtk/gtk4/settings/file-chooser/date-format
)

# Sonido de alerta: el nombre de una alerta de GNOME
# (/usr/share/sounds/gnome/default/alerts/<nombre>.ogg). Configuración la guarda
# como un tema de sonido propio (__custom, en ~/.local/share/sounds/) con enlaces
# a ese archivo; dotfiles-install.sh lo vuelve a armar.
# shellcheck disable=SC2034
gnome_alert_sound_file="alert-sound.txt"
# shellcheck disable=SC2034
gnome_alert_sounds_dir="/usr/share/sounds/gnome/default/alerts"
# shellcheck disable=SC2034
gnome_custom_sound_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/sounds/__custom"
