#!/usr/bin/env bash
set -euo pipefail

# Enlaza los dotfiles del repositorio en $HOME (la lista está en scripts/lib/links.sh)
# y, desde Nextcloud, la configuración y las llaves SSH en ~/.ssh, las fuentes en
# ~/.local/share/fonts y la VPN (install-wireguard.sh).
# Si ya existe un archivo (o un enlace hacia otro sitio), se respalda como
# <archivo>.bak.<fecha> antes de crear el enlace; de cada uno se guardan los
# respaldos más recientes (scripts/lib/backups.sh). Se puede ejecutar varias veces.
# Lo ejecuta fedora-install.sh, antes de extras-install.sh. Lo deshace, en parte,
# dotfiles-uninstall.sh.
#
# Uso: dotfiles-install.sh [--mostrar | --enlaces]
#   --mostrar  solo muestra los enlaces como órdenes mkdir y ln -sf, sin cambiar nada
#   --enlaces  solo crea los enlaces (también los de SSH) y copia las fuentes, sin
#              el resto (GNOME, RetroArch...); así lo ejecuta dotfiles-update.sh

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=scripts/lib/links.sh
source "${repo_root}/scripts/lib/links.sh"
# shellcheck source=scripts/lib/backups.sh
source "${repo_root}/scripts/lib/backups.sh"
# shellcheck source=scripts/lib/nextcloud.sh
source "${repo_root}/scripts/lib/nextcloud.sh"
nextcloud_hint="debe abrirse Nextcloud, iniciar sesión, sincronizar Respaldos e Importante y volver a ejecutarse este script"

# Un argumento desconocido no debe hacer la instalación completa (que vuelve a
# cargar los ajustes de GNOME del repositorio sobre los del escritorio)
if (($# > 1)) || [[ -n "${1:-}" && "$1" != --mostrar && "$1" != --enlaces ]]; then
  echo "Uso: dotfiles-install.sh [--mostrar | --enlaces]" >&2
  exit 1
fi

link() {
  local source
  source="$(link_source "$1")"
  local target="${HOME}/$2"

  if [[ ! -e "${source}" ]]; then
    echo "Omitido   ~/$2 (no existe $1)" >&2
    return
  fi

  if [[ -L "${target}" ]] && [[ "$(readlink "${target}")" == "${source}" ]]; then
    echo "Correcto  ~/$2"
  else
    if [[ -e "${target}" ]] || [[ -L "${target}" ]]; then
      mv "${target}" "${target}${backup_suffix}"
      echo "Respaldo  ~/$2 -> ~/$2${backup_suffix}"
    fi
    mkdir -p "$(dirname "${target}")"
    ln -s "${source}" "${target}"
    echo "Enlazado  ~/$2 -> $1"
  fi
  prune_backups "${target}"
}

if [[ "${1:-}" == "--mostrar" ]]; then
  # Desde la raíz del repositorio: los orígenes van relativos a $PWD
  # shellcheck disable=SC2016
  for entry in "${links[@]}"; do
    dir="$(dirname "${entry#*:}")"
    [[ "${dir}" == . ]] || printf 'mkdir -p "$HOME/%s"\n' "${dir}"
  done | sort -u
  # shellcheck disable=SC2016
  for entry in "${links[@]}"; do
    source="${entry%%:*}"
    [[ "${source}" == /* ]] || source="\$PWD/${source}"
    printf 'ln -sf "%s" "$HOME/%s"\n' "${source}" "${entry#*:}"
  done
  exit 0
fi

echo "Enlazando dotfiles desde ${repo_root}..."
# Instalaciones antiguas enlazaban ~/.claude/skills al directorio skills/ entero:
# las skills que sincroniza Claude (synced/) caían en el repositorio y, al
# enlazar SKILL.md por archivo, link() respaldaría el propio archivo del repo.
# Ahora es un directorio real con un enlace por archivo.
if [[ -L "${HOME}/.claude/skills" ]] && [[ "$(readlink "${HOME}/.claude/skills")" == "${repo_root}/skills" ]]; then
  rm "${HOME}/.claude/skills"
  echo "Quitado   ~/.claude/skills (enlace antiguo al directorio skills/)"
fi
for entry in "${links[@]}"; do
  link "${entry%%:*}" "${entry#*:}"
done

# SSH desde Nextcloud (Importante/SSH), igual en todos los equipos: config y las
# llaves *ed25519* (privadas y .pub) se enlazan en ~/.ssh. Va antes de --enlaces
# (así lo ejecuta dotfiles-update.sh): cada vez enlaza las llaves nuevas de esa
# carpeta y quita los enlaces cuyo archivo ya no está. Se omiten las copias en
# conflicto del cliente y los respaldos. ssh rechaza una llave privada que otros
# puedan leer, y el cliente de Nextcloud baja los archivos con 644: config y las
# privadas se dejan en 600. Antes de allowed_signers, que lee id_ed25519.pub.
ssh_remote="Importante/SSH"
if ssh_src="$(nextcloud_path "${ssh_remote}")"; then
  install -d -m 700 "${HOME}/.ssh"
  for ssh_link in "${HOME}"/.ssh/*; do
    if [[ -L "${ssh_link}" && ! -e "${ssh_link}" && "$(readlink "${ssh_link}")" == "${ssh_src}/"* ]]; then
      rm -- "${ssh_link}"
      echo "Quitado   ~/.ssh/${ssh_link##*/} (ya no está en ${ssh_remote})"
    fi
  done
  for ssh_file in "${ssh_src}/config" "${ssh_src}"/*ed25519*; do
    [[ -f "${ssh_file}" ]] || continue
    case "${ssh_file##*/}" in
    *conflicted* | *.bak*) continue ;;
    esac
    [[ "${ssh_file}" == *.pub ]] || chmod 600 "${ssh_file}"
    link "${ssh_file}" ".ssh/${ssh_file##*/}"
  done
else
  echo "Advertencia: ${ssh_remote} no está sincronizado; no se enlazó ~/.ssh (${nextcloud_hint})." >&2
fi

# Fuentes de Respaldos/Fonts/ en ~/.local/share/fonts, con rsync: las que faltan o
# cambiaron (tamaño o fecha; el cliente conserva la fecha del servidor). Va antes
# de --enlaces, como SSH: dotfiles-update.sh instala así las fuentes nuevas.
fonts_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/fonts"
fonts_remote="Respaldos/Fonts"
# Marca de la versión anterior, que descargaba un .zip
rm -f "${fonts_dir}/.dotfiles-fonts.sha256"
if ! fonts_src="$(nextcloud_path "${fonts_remote}")"; then
  echo "Advertencia: ${fonts_remote} no está sincronizado; ${nextcloud_hint}." >&2
else
  mkdir -p "${fonts_dir}"
  # --out-format: un nombre por archivo copiado, para contarlos (sin la carpeta,
  # que rsync también lista al actualizar su fecha)
  fonts_list="$(rsync -rt --chmod=F644 --out-format='%n' \
    --include='*.[tT][tT][fF]' --include='*.[oO][tT][fF]' --include='*.[tT][tT][cC]' --exclude='*' \
    "${fonts_src}/" "${fonts_dir}/")"
  fonts_copied="$(grep -c -v -e '/$' -e '^$' <<<"${fonts_list}" || true)"
  if ((fonts_copied > 0)); then
    echo "Copiadas  ${fonts_copied} fuentes de Nextcloud (${fonts_remote}) en ~/.local/share/fonts"
  else
    echo "Correcto  fuentes de Nextcloud en ~/.local/share/fonts"
  fi
fi

# Las reglas de fontconfig con target="scan" se aplican al reconstruir la caché
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f >/dev/null 2>&1 && echo "Caché de fuentes reconstruida"
fi

# Nombres propios de aplicaciones (gnome/menus/nombres.txt): una copia del .desktop
# del sistema en ~/.local/share/applications/, que tiene prioridad, con Name= cambiado
# y sin las traducciones del nombre ni NotShowIn (con NotShowIn=GNOME, GNOME la
# ocultaría), solo en [Desktop Entry] (las acciones conservan su nombre). Se regenera cada vez para seguir los cambios del paquete; la marca
# X-Dotfiles-Nombre distingue las copias propias, y la de una aplicación que salió
# de la lista se borra. Va antes de --enlaces, como SSH y las fuentes.
apps_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/applications"
names_file="${repo_root}/gnome/menus/nombres.txt"
declare -A app_names=()
while IFS='|' read -r app_file app_name; do
  [[ -n "${app_file}" && "${app_file}" != \#* ]] || continue
  app_names["${app_file}"]="${app_name}"
done <"${names_file}"
mkdir -p "${apps_dir}"
for app_copy in "${apps_dir}"/*.desktop; do
  if [[ -f "${app_copy}" && ! -L "${app_copy}" ]] && grep -q '^X-Dotfiles-Nombre=' "${app_copy}" &&
    [[ -z "${app_names[${app_copy##*/}]:-}" ]]; then
    rm -f "${app_copy}"
    echo "Quitado   nombre propio de ${app_copy##*/}"
  fi
done
for app_file in "${!app_names[@]}"; do
  app_src=""
  IFS=':' read -ra data_dirs <<<"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  for data_dir in "${data_dirs[@]}"; do
    if [[ -f "${data_dir}/applications/${app_file}" ]]; then
      app_src="${data_dir}/applications/${app_file}"
      break
    fi
  done
  if [[ -z "${app_src}" ]]; then
    echo "Advertencia: ${app_file} no está instalado; no se le cambió el nombre." >&2
    continue
  fi
  app_tmp="$(mktemp)"
  awk -v name="${app_names[${app_file}]}" '
    /^\[/ { main = ($0 == "[Desktop Entry]") }
    main && /^Name(\[[^]]*\])?=/ { if ($0 ~ /^Name=/) print "Name=" name; next }
    main && /^NotShowIn=/ { next }
    { print }
    main && $0 == "[Desktop Entry]" { print "X-Dotfiles-Nombre=true" }
  ' "${app_src}" >"${app_tmp}"
  if cmp -s "${app_tmp}" "${apps_dir}/${app_file}"; then
    rm -f "${app_tmp}"
  else
    install -m 644 "${app_tmp}" "${apps_dir}/${app_file}"
    rm -f "${app_tmp}"
    echo "Nombre    ${app_file}: ${app_names[${app_file}]}"
  fi
done

# VPN de Sea Dragon desde Nextcloud (Importante/VPN). Va antes de --enlaces, como
# SSH: dotfiles-update.sh aplica así una configuración nueva del servidor. Un
# archivo con errores no detiene el resto (el script ya explicó el problema).
if ! bash "${repo_root}/scripts/install-wireguard.sh"; then
  echo "Advertencia: no se configuró la VPN; se sigue con lo demás." >&2
fi

if [[ "${1:-}" == "--enlaces" ]]; then
  exit 0
fi

echo "Creando directorios de trabajo..."
install -d -m 700 "${HOME}/.config/npm"

# npm no admite "include" en npmrc: si existe el archivo privado (token, fuera del
# repositorio), se combina con ~/.npmrc en npmrc-effective, que zsh/zshenv exporta
# como NPM_CONFIG_USERCONFIG. Debe volver a ejecutarse al cambiar cualquiera de los dos.
npm_private="${HOME}/.config/npm/npmrc-private"
npm_effective="${HOME}/.config/npm/npmrc-effective"
if [[ -f "${npm_private}" ]]; then
  (umask 077 && { cat "${HOME}/.npmrc" && echo && cat "${npm_private}"; } >"${npm_effective}")
  # umask no cambia los permisos de un archivo que ya existía
  chmod 600 "${npm_effective}"
  echo "Generado  ${npm_effective} (~/.npmrc + npmrc-private)"
elif [[ -e "${npm_effective}" ]]; then
  # Sin archivo privado no debe quedar un token antiguo
  rm -f "${npm_effective}"
  echo "Eliminado ${npm_effective} (no hay npmrc-private)"
fi
mkdir -p "${HOME}/.vim/backup" "${HOME}/.vim/swap" "${HOME}/.vim/undodir" "${HOME}/.vim/snippets"
# Historiales de psql, uno por base de datos (HISTFILE en postgresql/psqlrc)
install -d -m 700 "${XDG_STATE_HOME:-${HOME}/.local/state}/psql"
# ROMs para RetroArch (una carpeta por consola) y para MAME (ruta por defecto de Fedora)
mkdir -p "${HOME}/Juegos/Nintendo" "${HOME}/Juegos/Super Nintendo" "${HOME}/Juegos/PlayStation" \
  "${HOME}/Juegos/Sega Genesis" "${HOME}/.local/share/mame/roms"

# Firmantes permitidos para verificar commits firmados con SSH (gpg.ssh.allowedSignersFile):
# la misma llave con el correo general (el de GitHub) y con el de Sea Dragon
signing_pubkey="${HOME}/.ssh/id_ed25519.pub"
allowed_signers="${HOME}/.config/git/allowed_signers"
if [[ -f "${signing_pubkey}" ]]; then
  install -d "$(dirname "${allowed_signers}")"
  for gitconfig in gitconfig gitconfig-seadragon; do
    email="$(git config --file "${repo_root}/git/${gitconfig}" user.email)"
    printf '%s namespaces="git" %s\n' "${email}" "$(cat "${signing_pubkey}")"
  done >"${allowed_signers}"
  echo "Generado  ${allowed_signers}"
else
  echo "Advertencia: no existe ${signing_pubkey}; no se generó ${allowed_signers}." >&2
fi

# Hook de pre-commit de este repositorio (ShellCheck y shfmt con scripts/lint.sh)
git -C "${repo_root}" config core.hooksPath .githooks
echo "Activado  hook de pre-commit (.githooks/pre-commit)"

# Google Chrome como navegador predeterminado (enlaces web y archivos HTML)
browser_desktop="google-chrome.desktop"
if [[ ! -f "/usr/share/applications/${browser_desktop}" ]]; then
  echo "Advertencia: Google Chrome no está instalado; no se cambió el navegador predeterminado." >&2
elif xdg-settings set default-web-browser "${browser_desktop}" &&
  xdg-mime default "${browser_desktop}" x-scheme-handler/http x-scheme-handler/https \
    x-scheme-handler/about x-scheme-handler/unknown text/html application/xhtml+xml; then
  echo "Navegador ${browser_desktop}"
else
  echo "Advertencia: no se pudo fijar ${browser_desktop} como navegador predeterminado." >&2
fi

# Fuente monoespaciada del sistema (la usa Ptyxis). Puede fijarse antes de que
# extras-install.sh instale la fuente: GNOME usa otra hasta que exista.
monospace_font="FiraCode Nerd Font Mono 11"
if ! gsettings list-schemas 2>/dev/null | grep -qx org.gnome.desktop.interface; then
  echo "Advertencia: no hay sesión de GNOME; no se cambió la fuente monoespaciada." >&2
elif gsettings set org.gnome.desktop.interface monospace-font-name "${monospace_font}"; then
  echo "Fuente    ${monospace_font} (monoespaciada del sistema)"
  if gsettings list-schemas | grep -qx org.gnome.Ptyxis; then
    gsettings set org.gnome.Ptyxis use-system-font true
  fi
else
  echo "Advertencia: no se pudo fijar la fuente monoespaciada." >&2
fi

# Paleta Dracula (la de estos dotfiles; viene con Ptyxis) en el perfil por defecto
# de Ptyxis. Si Ptyxis no se ha abierto nunca, no hay perfiles: se crea uno, como
# haría Ptyxis al iniciar (identificador de 32 caracteres hexadecimales).
if ! gsettings list-schemas 2>/dev/null | grep -qx org.gnome.Ptyxis; then
  echo "Advertencia: no está Ptyxis (o no hay sesión de GNOME); no se cambió su paleta." >&2
else
  ptyxis_profile="$(gsettings get org.gnome.Ptyxis default-profile-uuid | tr -d "'")"
  if [[ -z "${ptyxis_profile}" ]]; then
    ptyxis_profile="$(uuidgen | tr -d '-')"
    gsettings set org.gnome.Ptyxis profile-uuids "['${ptyxis_profile}']"
    gsettings set org.gnome.Ptyxis default-profile-uuid "${ptyxis_profile}"
  fi
  if gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${ptyxis_profile}/" palette dracula; then
    echo "Paleta    Dracula en Ptyxis (perfil por defecto)"
  else
    echo "Advertencia: no se pudo fijar la paleta Dracula en Ptyxis." >&2
  fi
fi

# Fondo de escritorio (claro y oscuro) y de la pantalla de bloqueo: ~/.config/background, el archivo que usa
# GNOME al elegir una imagen en Configuración, enlazado a gnome/background.jpg
wallpaper="${HOME}/.config/background"
if ! gsettings list-schemas 2>/dev/null | grep -qx org.gnome.desktop.background; then
  echo "Advertencia: no hay sesión de GNOME; no se cambió el fondo de escritorio." >&2
elif [[ ! -L "${wallpaper}" ]]; then
  echo "Advertencia: no existe gnome/background.jpg; no se cambió el fondo de escritorio." >&2
elif gsettings set org.gnome.desktop.background picture-uri "file://${wallpaper}" &&
  gsettings set org.gnome.desktop.background picture-uri-dark "file://${wallpaper}" &&
  gsettings set org.gnome.desktop.background picture-options zoom &&
  gsettings set org.gnome.desktop.screensaver picture-uri "file://${wallpaper}" &&
  gsettings set org.gnome.desktop.screensaver picture-options zoom; then
  echo "Fondo     gnome/background.jpg (escritorio y pantalla de bloqueo)"
else
  echo "Advertencia: no se pudo cambiar el fondo de escritorio." >&2
fi

# Foto de perfil (profile.webp): la de GNOME (inicio de sesión, menú del sistema y
# Configuración → Usuarios) es la de AccountsService, que copia el archivo en
# /var/lib/AccountsService/icons/<usuario>. Se cambia solo si esa copia es
# distinta; cambiar la propia no pide contraseña. accounts-daemon no puede leer
# archivos de $HOME ("reading file ... failed"): se le pasa una copia en /var/tmp.
profile_picture="${repo_root}/profile.webp"
account_icon="/var/lib/AccountsService/icons/$(id -un)"
set_profile_picture() {
  local copy rc=0
  copy="$(mktemp /var/tmp/profile.XXXXXX.webp)"
  cp -f "${profile_picture}" "${copy}"
  chmod 644 "${copy}"
  busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" \
    org.freedesktop.Accounts.User SetIconFile s "${copy}" >/dev/null 2>&1 || rc=$?
  rm -f "${copy}"
  return "${rc}"
}
if [[ ! -f "${profile_picture}" ]]; then
  echo "Advertencia: no existe profile.webp; no se cambió la foto de perfil." >&2
elif cmp -s "${profile_picture}" "${account_icon}"; then
  echo "Correcto  foto de perfil (profile.webp)"
elif set_profile_picture; then
  echo "Foto      profile.webp (perfil de GNOME)"
else
  echo "Advertencia: no se pudo cambiar la foto de perfil (AccountsService)." >&2
fi

# Preferencias de En Croissant (encroissant/settings.json), en su localStorage; se
# vuelcan con scripts/export-gnome-settings.sh. Si está abierto, no se cargan.
python3 -I "${repo_root}/scripts/lib/encroissant-settings.py" aplicar ||
  echo "Advertencia: no se pudieron cargar las preferencias de En Croissant." >&2

# Configuración de GNOME (la lista está en scripts/lib/gnome-dconf.sh): los
# valores de las extensiones y cuáles quedan activas, los ajustes del escritorio
# (gnome/settings.dconf) y el sonido de alerta. Se vuelcan con
# scripts/export-gnome-settings.sh. Las extensiones son paquetes de packages.txt;
# las recién instaladas aparecen al volver a iniciar sesión.
# shellcheck source=scripts/lib/gnome-dconf.sh
source "${repo_root}/scripts/lib/gnome-dconf.sh"
if ! command -v dconf >/dev/null 2>&1 ||
  ! gsettings list-schemas 2>/dev/null | grep -qx org.gnome.shell; then
  echo "Advertencia: no hay sesión de GNOME; no se cargó su configuración." >&2
else
  for entry in "${gnome_dconf[@]}"; do
    file="${entry%%:*}"
    if [[ -f "${repo_root}/gnome/${file}" ]] && dconf load "${entry#*:}" <"${repo_root}/gnome/${file}"; then
      echo "Cargado   gnome/${file}"
    else
      echo "Advertencia: no se pudo cargar gnome/${file}." >&2
    fi
  done

  extensions_file="${repo_root}/gnome/${gnome_extensions_file}"
  if [[ -f "${extensions_file}" ]]; then
    # Una por línea -> ['a@b', 'c@d']
    enabled="[$(sed "/^$/d; s/.*/'&'/" "${extensions_file}" | paste -sd, - | sed 's/,/, /g')]"
    if gsettings set org.gnome.shell enabled-extensions "${enabled}"; then
      echo "Activadas las extensiones de gnome/${gnome_extensions_file}"
    else
      echo "Advertencia: no se pudieron activar las extensiones de GNOME." >&2
    fi
  fi

  # Ajustes del escritorio, con rutas absolutas: dconf load / solo escribe las
  # claves del archivo y deja las demás como están
  settings_file="${repo_root}/gnome/${gnome_settings_file}"
  if [[ -f "${settings_file}" ]] && dconf load / <"${settings_file}"; then
    echo "Cargado   gnome/${gnome_settings_file}"
  else
    echo "Advertencia: no se pudo cargar gnome/${gnome_settings_file}." >&2
  fi

  # Sonido de alerta: el tema propio (__custom) que arma Configuración al elegir
  # una alerta, con enlaces a ella
  alert="$(sed -n '1p' "${repo_root}/gnome/${gnome_alert_sound_file}" 2>/dev/null || true)"
  if [[ -z "${alert}" ]]; then
    :
  elif [[ ! -f "${gnome_alert_sounds_dir}/${alert}.ogg" ]]; then
    echo "Advertencia: no existe la alerta ${gnome_alert_sounds_dir}/${alert}.ogg; no se cambió el sonido." >&2
  else
    mkdir -p "${gnome_custom_sound_dir}"
    printf '[Sound Theme]\nName=Personalizado\nInherits=freedesktop\nDirectories=.\n' \
      >"${gnome_custom_sound_dir}/index.theme"
    for sound in bell-terminal bell-window-system; do
      ln -sfn "${gnome_alert_sounds_dir}/${alert}.ogg" "${gnome_custom_sound_dir}/${sound}.ogg"
    done
    gsettings set org.gnome.desktop.sound theme-name '__custom'
    echo "Sonido    alerta «${alert}» (gnome/${gnome_alert_sound_file})"
  fi
fi

# Perfiles de mandos de RetroArch. RetroArch lee un solo directorio, así que en
# ~/.config/retroarch/autoconfig/ se enlazan los perfiles del sistema y, encima,
# los corregidos del repositorio (retroarch/autoconfig/<driver>/), que reemplazan
# a los del mismo nombre. Los directorios sin perfiles propios se enlazan enteros.
system_autoconfig="/usr/share/libretro/autoconfig"
user_autoconfig="${HOME}/.config/retroarch/autoconfig"
if [[ -d "${system_autoconfig}" ]]; then
  mkdir -p "${user_autoconfig}"
  for system_dir in "${system_autoconfig}"/*/; do
    driver="$(basename "${system_dir}")"
    if [[ -d "${repo_root}/retroarch/autoconfig/${driver}" ]]; then
      [[ -L "${user_autoconfig}/${driver}" ]] && rm "${user_autoconfig}/${driver}"
      mkdir -p "${user_autoconfig}/${driver}"
      ln -sf "${system_dir}"*.cfg "${user_autoconfig}/${driver}/"
      ln -sf "${repo_root}/retroarch/autoconfig/${driver}/"*.cfg "${user_autoconfig}/${driver}/"
    elif [[ ! -e "${user_autoconfig}/${driver}" ]] || [[ -L "${user_autoconfig}/${driver}" ]]; then
      ln -sfn "${system_dir%/}" "${user_autoconfig}/${driver}"
    fi
  done
  # Enlaces a perfiles que ya no existen (por una actualización de RetroArch)
  find "${user_autoconfig}" -mindepth 2 -maxdepth 2 -xtype l -delete
  echo "RetroArch perfiles de mandos en ~/.config/retroarch/autoconfig"
else
  echo "Advertencia: no está ${system_autoconfig} (paquete retroarch); no se armaron los perfiles de mandos." >&2
fi

# Cores de RetroArch. Como con los perfiles, RetroArch lee un solo directorio:
# ~/.config/retroarch/cores/ enlaza los cores del sistema (paquetes libretro-*)
# y los compilados en ~/.local/lib/libretro/ (install-genesis-plus-gx.sh).
cores_dir="${HOME}/.config/retroarch/cores"
mkdir -p "${cores_dir}"
for core in /usr/lib64/libretro/*.so "${HOME}"/.local/lib/libretro/*.so; do
  [[ -e "${core}" ]] && ln -sf "${core}" "${cores_dir}/"
done
# Enlaces a cores ya desinstalados
find "${cores_dir}" -maxdepth 1 -xtype l -delete
echo "RetroArch cores en ~/.config/retroarch/cores"

# apply_keys <programa> <proceso> <archivo del repositorio> <archivo del programa>
# Aplica las claves «clave = valor» del archivo del repositorio sobre el del
# programa, que no se enlaza porque el programa lo reescribe entero al salir (así
# lo hacen RetroArch y btop): reemplaza las que ya existen y agrega al final las
# que faltan. Si el programa no se ha abierto nunca, el archivo se crea solo con
# esas claves. Con el programa abierto no se toca: lo sobrescribiría al salir.
apply_keys() {
  local name="$1" process="$2" source="${repo_root}/$3" target="$4" tmp
  if pgrep -x "${process}" >/dev/null 2>&1; then
    echo "Advertencia: ${name} está abierto; no se cambió su configuración (la sobrescribiría al salir)." >&2
    return
  fi
  mkdir -p "$(dirname "${target}")"
  [[ -f "${target}" ]] || : >"${target}"
  tmp="$(mktemp "${target}.XXXXXX")"
  # Primero se leen las claves del repositorio; luego, en el archivo del programa,
  # se reemplazan las que ya existen y al final se agregan las que faltan.
  awk '
    NR == FNR {
      if ($0 ~ /^[a-z0-9_]+ = /) { value[$1] = $0; order[++n] = $1 }
      next
    }
    ($1 in value) { print value[$1]; done[$1] = 1; next }
    { print }
    END { for (i = 1; i <= n; i++) if (!(order[i] in done)) print value[order[i]] }
  ' "${source}" "${target}" >"${tmp}"
  chmod --reference="${target}" "${tmp}"
  mv "${tmp}" "${target}"
  echo "${name} $3 aplicado en ${target/#${HOME}/\~}"
}

apply_keys RetroArch retroarch retroarch/retroarch.cfg "${HOME}/.config/retroarch/retroarch.cfg"
# btop: el tema Dracula
apply_keys btop btop btop/btop.conf "${XDG_CONFIG_HOME:-${HOME}/.config}/btop/btop.conf"

# gh: los alias de gh/aliases.yml. ~/.config/gh/config.yml no se enlaza porque gh
# lo reescribe (gh config set, gh alias set); --clobber reemplaza los que ya existen.
if ! command -v gh >/dev/null 2>&1; then
  echo "Advertencia: gh no está instalado; no se importaron sus alias." >&2
elif gh alias import --clobber "${repo_root}/gh/aliases.yml" >/dev/null; then
  echo "gh gh/aliases.yml importado en ~/.config/gh/config.yml"
else
  echo "Advertencia: no se pudieron importar los alias de gh (gh/aliases.yml)." >&2
fi

# RetroArch: archivo de sistema de PCSX ReARMED, desde Nextcloud. Se copia solo
# si falta o no coincide su SHA-256; si había otro (o un enlace), se respalda.
system_file="${HOME}/.config/retroarch/system/scph5501.bin"
system_file_remote="Respaldos/scph5501.bin"
system_file_sha256="11052b6499e466bbf0a709b1f9cb6834a9418e66680387912451e971cf8a1fef"
if [[ -f "${system_file}" ]] && [[ ! -L "${system_file}" ]] &&
  [[ "$(sha256sum "${system_file}" | cut -d ' ' -f 1)" == "${system_file_sha256}" ]]; then
  echo "Correcto  ~/.config/retroarch/system/scph5501.bin"
elif ! system_file_src="$(nextcloud_path "${system_file_remote}")"; then
  echo "Advertencia: ${system_file_remote} no está sincronizado; ${nextcloud_hint}." >&2
elif [[ "$(sha256sum "${system_file_src}" | cut -d ' ' -f 1)" != "${system_file_sha256}" ]]; then
  echo "Advertencia: ${system_file_remote} (Nextcloud) no coincide con el SHA-256 esperado." >&2
else
  mkdir -p "$(dirname "${system_file}")"
  if [[ -e "${system_file}" ]] || [[ -L "${system_file}" ]]; then
    mv "${system_file}" "${system_file}${backup_suffix}"
    echo "Respaldo  ~/.config/retroarch/system/scph5501.bin -> scph5501.bin${backup_suffix}"
  fi
  install -m 644 "${system_file_src}" "${system_file}"
  echo "Copiado   ~/.config/retroarch/system/scph5501.bin (Nextcloud: ${system_file_remote})"
fi
prune_backups "${system_file}"

# Saludo matutino (systemd/buenos-dias.timer); requiere la sesión del usuario
if systemctl --user daemon-reload && systemctl --user enable --now buenos-dias.timer; then
  echo "Activado  buenos-dias.timer (todos los días a las 08:00)"
else
  echo "Advertencia: no se pudo activar buenos-dias.timer; debe ejecutarse a mano:" >&2
  echo "  systemctl --user daemon-reload && systemctl --user enable --now buenos-dias.timer" >&2
fi

# Respaldo de Vaultwarden en KeePassXC (systemd/bw2kp.timer, cada 6 horas): solo si
# ~/.zshsecrets define KP_PASSWORD, porque sin sus variables el servicio fallaría
if grep -qs '^export KP_PASSWORD=' "${HOME}/.zshsecrets"; then
  if systemctl --user daemon-reload && systemctl --user enable --now bw2kp.timer; then
    echo "Activado  bw2kp.timer (cada 6 horas: 00:00, 06:00, 12:00 y 18:00)"
  else
    echo "Advertencia: no se pudo activar bw2kp.timer; debe ejecutarse a mano:" >&2
    echo "  systemctl --user daemon-reload && systemctl --user enable --now bw2kp.timer" >&2
  fi
else
  echo "Omitido   bw2kp.timer: ~/.zshsecrets no define KP_PASSWORD (ver docs/escritorio.md)"
fi

echo "Listo. Debe abrirse una terminal nueva para que los cambios surtan efecto."
