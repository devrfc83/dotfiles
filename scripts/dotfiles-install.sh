#!/usr/bin/env bash
set -euo pipefail

# Enlaza los dotfiles del repositorio en $HOME.
# Si ya existe un archivo (o un enlace hacia otro sitio), se respalda como
# <archivo>.bak.<fecha> antes de crear el enlace. Se puede ejecutar varias veces.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
backup_suffix=".bak.$(date +%Y%m%d%H%M%S)"

# origen (relativo al repositorio, o ruta absoluta):destino (relativo a $HOME)
links=(
  "curl/curlrc:.curlrc"
  "codium/settings.json:.config/VSCodium/User/settings.json"
  "codium/cursor-settings.json:.config/Cursor/User/settings.json"
  "editorconfig/editorconfig:.editorconfig"
  "fontconfig/conf.d/50-aptos-display.conf:.config/fontconfig/conf.d/50-aptos-display.conf"
  "gnome/background.jpg:.config/background"
  "git/gitconfig:.gitconfig"
  "git/gitconfig-personal:.gitconfig-personal"
  "git/gitignore:.gitignore"
  "git/gitattributes:.gitattributes"
  "input/dircolors:.dircolors"
  "input/inputrc:.inputrc"
  "screen/screenrc:.screenrc"
  "tmux/tmux.conf:.tmux.conf"
  "tmux/tmux-weather.sh:.local/bin/tmux-weather"
  "vim/vimrc:.vimrc"
  "node/npmrc:.npmrc"
  "zsh/zlogin:.zlogin"
  "zsh/zlogout:.zlogout"
  "zsh/zshenv:.zshenv"
  "zsh/zprofile:.zprofile"
  "zsh/zshrc:.zshrc"
  "zsh/zshoptions:.zshoptions"
  "zsh/zshaliases:.zshaliases"
  "zsh/zshfunctions:.zshfunctions"
  "zsh/scripts/buenos_dias.zsh:.local/bin/buenos-dias"
  "systemd/buenos-dias.service:.config/systemd/user/buenos-dias.service"
  "systemd/buenos-dias.timer:.config/systemd/user/buenos-dias.timer"
  # vimx (Vim con portapapeles, paquete vim-X11) con los nombres de siempre;
  # Vim elige el modo según el nombre (vimdiff compara, view abre en solo lectura)
  "/usr/bin/vimx:.local/bin/vim"
  "/usr/bin/vimx:.local/bin/vi"
  "/usr/bin/vimx:.local/bin/vimdiff"
  "/usr/bin/vimx:.local/bin/view"
)

link() {
  local source="$1"
  [[ "${source}" == /* ]] || source="${repo_root}/$1"
  local target="${HOME}/$2"

  if [[ ! -e "${source}" ]]; then
    echo "Omitido   ~/$2 (no existe $1)" >&2
    return
  fi

  if [[ -L "${target}" ]] && [[ "$(readlink "${target}")" == "${source}" ]]; then
    echo "Correcto  ~/$2"
    return
  fi

  if [[ -e "${target}" ]] || [[ -L "${target}" ]]; then
    mv "${target}" "${target}${backup_suffix}"
    echo "Respaldo  ~/$2 -> ~/$2${backup_suffix}"
  fi

  mkdir -p "$(dirname "${target}")"
  ln -s "${source}" "${target}"
  echo "Enlazado  ~/$2 -> $1"
}

echo "Enlazando dotfiles desde ${repo_root}..."
for entry in "${links[@]}"; do
  link "${entry%%:*}" "${entry#*:}"
done

# Fuentes adicionales en ~/.local/share/fonts. Se descargan y se verifica su
# SHA-256; una marca con ese valor evita repetir la descarga.
fonts_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/fonts"
fonts_src="ZGV2cmZjODNodHRwczovL3d3dy5kZXZyZmM4My5jb20vZG93bmxvYWQvZm9udHMuemlw"
fonts_sha256="9d5659cd67c64507fef61029f60d8d86b4d736ee330275bafc2a0ae84441726c"
fonts_mark="${fonts_dir}/.dotfiles-fonts.sha256"
if [[ "$(cat "${fonts_mark}" 2>/dev/null)" == "${fonts_sha256}" ]]; then
  echo "Correcto  fuentes en ~/.local/share/fonts"
else
  fonts_tmp="$(mktemp)"
  fonts_url="$(base64 -d <<<"${fonts_src}")"
  if curl -fsSL -o "${fonts_tmp}" "${fonts_url#devrfc83}" &&
    [[ "$(sha256sum "${fonts_tmp}" | cut -d ' ' -f 1)" == "${fonts_sha256}" ]]; then
    mkdir -p "${fonts_dir}"
    unzip -o -j -q "${fonts_tmp}" '*.ttf' -d "${fonts_dir}"
    echo "${fonts_sha256}" >"${fonts_mark}"
    echo "Instalado fuentes en ~/.local/share/fonts"
  else
    echo "Advertencia: no se pudieron descargar las fuentes, o no coincide su SHA-256." >&2
  fi
  rm -f "${fonts_tmp}"
fi

# Las reglas de fontconfig con target="scan" se aplican al reconstruir la caché
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f >/dev/null 2>&1 && echo "Caché de fuentes reconstruida"
fi

echo "Creando directorios de trabajo..."
install -d -m 700 "${HOME}/.config/npm"
mkdir -p "${HOME}/.vim/backup" "${HOME}/.vim/swap" "${HOME}/.vim/undodir" "${HOME}/.vim/snippets"
# ROMs para RetroArch (una carpeta por consola) y para MAME (ruta por defecto de Fedora)
mkdir -p "${HOME}/Juegos/Nintendo" "${HOME}/Juegos/Super Nintendo" "${HOME}/Juegos/PlayStation" \
  "${HOME}/Juegos/Sega Genesis" "${HOME}/.local/share/mame/roms"

# Firmantes permitidos para verificar commits firmados con SSH (gpg.ssh.allowedSignersFile)
signing_pubkey="${HOME}/.ssh/id_ed25519.pub"
allowed_signers="${HOME}/.config/git/allowed_signers"
if [[ -f "${signing_pubkey}" ]]; then
  email="$(git config --file "${repo_root}/git/gitconfig" user.email)"
  install -d "$(dirname "${allowed_signers}")"
  printf '%s namespaces="git" %s\n' "${email}" "$(cat "${signing_pubkey}")" >"${allowed_signers}"
  echo "Generado  ${allowed_signers}"
else
  echo "Advertencia: no existe ${signing_pubkey}; no se generó ${allowed_signers}." >&2
fi

# Chromium como navegador predeterminado (enlaces web y archivos HTML)
browser_desktop="chromium-browser.desktop"
if [[ ! -f "/usr/share/applications/${browser_desktop}" ]]; then
  echo "Advertencia: Chromium no está instalado; no se cambió el navegador predeterminado." >&2
elif xdg-settings set default-web-browser "${browser_desktop}" &&
  xdg-mime default "${browser_desktop}" x-scheme-handler/http x-scheme-handler/https \
    x-scheme-handler/about x-scheme-handler/unknown text/html application/xhtml+xml; then
  echo "Navegador ${browser_desktop}"
else
  echo "Advertencia: no se pudo fijar ${browser_desktop} como navegador predeterminado." >&2
fi

# Fuente monoespaciada del sistema (la usa Ptyxis). Puede fijarse antes de que
# extras-install.sh instale la fuente: GNOME usa otra hasta que exista.
monospace_font="FiraCode Nerd Font Mono 10"
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

# Extensiones de GNOME: sus valores (gnome/*.dconf) y cuáles quedan activas.
# Se vuelcan con scripts/export-gnome-settings.sh. Las extensiones son paquetes
# de packages.txt; las recién instaladas aparecen al volver a iniciar sesión.
# shellcheck source=scripts/lib/gnome-dconf.sh
source "${repo_root}/scripts/lib/gnome-dconf.sh"
if ! command -v dconf >/dev/null 2>&1 ||
  ! gsettings list-schemas 2>/dev/null | grep -qx org.gnome.shell; then
  echo "Advertencia: no hay sesión de GNOME; no se cargó la configuración de las extensiones." >&2
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

# RetroArch: aplica las claves de retroarch/retroarch.cfg sobre el archivo de
# RetroArch (no se enlaza porque RetroArch lo reescribe entero al salir).
# Si RetroArch no se ha abierto nunca, el archivo se crea solo con esas claves.
retroarch_cfg="${HOME}/.config/retroarch/retroarch.cfg"
if pgrep -x retroarch >/dev/null 2>&1; then
  echo "Advertencia: RetroArch está abierto; no se cambió su configuración (la sobrescribiría al salir)." >&2
else
  mkdir -p "$(dirname "${retroarch_cfg}")"
  [[ -f "${retroarch_cfg}" ]] || : >"${retroarch_cfg}"
  retroarch_tmp="$(mktemp "${retroarch_cfg}.XXXXXX")"
  # Primero se leen las claves del repositorio; luego, en el archivo de RetroArch,
  # se reemplazan las que ya existen y al final se agregan las que faltan.
  awk '
    NR == FNR {
      if ($0 ~ /^[a-z0-9_]+ = /) { value[$1] = $0; order[++n] = $1 }
      next
    }
    ($1 in value) { print value[$1]; done[$1] = 1; next }
    { print }
    END { for (i = 1; i <= n; i++) if (!(order[i] in done)) print value[order[i]] }
  ' "${repo_root}/retroarch/retroarch.cfg" "${retroarch_cfg}" >"${retroarch_tmp}"
  chmod --reference="${retroarch_cfg}" "${retroarch_tmp}"
  mv "${retroarch_tmp}" "${retroarch_cfg}"
  echo "RetroArch retroarch/retroarch.cfg aplicado en ~/.config/retroarch/retroarch.cfg"
fi

# RetroArch: archivo de sistema de PCSX ReARMED. Se descarga solo si falta o no
# coincide su SHA-256; si había otro (o un enlace), se respalda.
system_file="${HOME}/.config/retroarch/system/scph5501.bin"
system_file_src="ZGV2cmZjODNodHRwczovL3d3dy5kZXZyZmM4My5jb20vZG93bmxvYWQvcHMxL3NjcGg1NTAxLmJpbg=="
system_file_sha256="11052b6499e466bbf0a709b1f9cb6834a9418e66680387912451e971cf8a1fef"
if [[ -f "${system_file}" ]] && [[ ! -L "${system_file}" ]] &&
  [[ "$(sha256sum "${system_file}" | cut -d ' ' -f 1)" == "${system_file_sha256}" ]]; then
  echo "Correcto  ~/.config/retroarch/system/scph5501.bin"
else
  mkdir -p "$(dirname "${system_file}")"
  system_file_tmp="$(mktemp "${system_file}.XXXXXX")"
  system_file_url="$(base64 -d <<<"${system_file_src}")"
  if curl -fsSL -o "${system_file_tmp}" "${system_file_url#devrfc83}" &&
    [[ "$(sha256sum "${system_file_tmp}" | cut -d ' ' -f 1)" == "${system_file_sha256}" ]]; then
    if [[ -e "${system_file}" ]] || [[ -L "${system_file}" ]]; then
      mv "${system_file}" "${system_file}${backup_suffix}"
      echo "Respaldo  ~/.config/retroarch/system/scph5501.bin -> scph5501.bin${backup_suffix}"
    fi
    chmod 644 "${system_file_tmp}"
    mv "${system_file_tmp}" "${system_file}"
    echo "Descargado ~/.config/retroarch/system/scph5501.bin"
  else
    rm -f "${system_file_tmp}"
    echo "Advertencia: no se pudo descargar ~/.config/retroarch/system/scph5501.bin, o no coincide su SHA-256." >&2
  fi
fi

# Saludo matutino (systemd/buenos-dias.timer); requiere la sesión del usuario
if systemctl --user daemon-reload && systemctl --user enable --now buenos-dias.timer; then
  echo "Activado  buenos-dias.timer (todos los días a las 08:00)"
else
  echo "Advertencia: no se pudo activar buenos-dias.timer; debe ejecutarse a mano:" >&2
  echo "  systemctl --user daemon-reload && systemctl --user enable --now buenos-dias.timer" >&2
fi

echo "Listo. Debe abrirse una terminal nueva para que los cambios surtan efecto."
