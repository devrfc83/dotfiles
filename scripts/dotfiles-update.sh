#!/usr/bin/env bash
set -euo pipefail

# Actualiza en un solo comando todo lo que instalan estos dotfiles:
# - los paquetes DNF (packages.txt y el resto del sistema), con rkhunter antes
#   (revisión) y después (base de referencia, si la revisión no tuvo avisos), y
#   los que se agregaron a packages.txt desde la última vez;
# - los enlaces nuevos de scripts/lib/links.sh (dotfiles-install.sh --enlaces);
# - el firmware, con fwupd (pide confirmación por cada dispositivo);
# - Node.js: la última versión con fnm, que queda como predeterminada (antes de
#   los extras, que reinstalan en ella los paquetes globales de npm);
# - lo de extras-install.sh: rustup, fnm, gopls, delve y govulncheck, Flutter
#   (flutter upgrade), el Android SDK (android sdk update), oh-my-zsh y los
#   plugins de zsh y tmux, los crates de Cargo, los paquetes globales de npm, los
#   plugins de Vim, los programas
#   compilados o descargados en versión fija, como Go y Mailpit (solo si cambió
#   la versión), y opencode y opencode Desktop (Zed y Android Studio se
#   actualizan solos);
# - los paquetes globales de Composer (composer global update);
# - pipx (edge-tts, piper-tts, sqlmap) y las extensiones de VSCodium y Cursor;
# - al final, check-versions.sh avisa qué versiones fijas tienen una más nueva.
# Debe ejecutarse sin sudo (lo pide cuando hace falta). Si un paso falla, sigue
# con los demás y lo informa al final.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ((EUID == 0)); then
  echo "Este script debe ejecutarse como usuario normal, sin sudo." >&2
  exit 1
fi

# shellcheck source=scripts/lib/steps.sh
source "${scripts_dir}/lib/steps.sh"

# rkhunter: antes de actualizar, se revisa el sistema contra su base de referencia.
# La base se actualiza después de dnf upgrade (si no, cada archivo que cambia una
# actualización sería un aviso) solo si la revisión no tiene avisos, o si los
# únicos son cambios de archivos de paquetes que rpm -V confirma (rkhunter_solo_paquetes):
# un cambio ajeno a los paquetes sigue dejando la base como estaba.
#
# rkhunter_solo_paquetes <informe>: sí si el informe solo tiene avisos de
# propiedades de archivos, y todos pertenecen a un paquete cuyo rpm -V está limpio
rkhunter_solo_paquetes() {
  local report="$1" headers properties files file
  headers="$(grep -c 'Warning:' "${report}" || true)"
  properties="$(grep -c 'file properties have changed' "${report}" || true)"
  files="$(sed -n -E 's/^(\[[0-9:]+\])? *File: //p' "${report}" | sort -u)"
  if ((headers == 0 || headers != properties)) || [[ -z "${files}" ]]; then
    return 1
  fi
  while IFS= read -r file; do
    sudo rpm -qf "${file}" >/dev/null 2>&1 || return 1
    [[ -z "$(sudo rpm -Vf "${file}" 2>&1)" ]] || return 1
  done <<<"${files}"
  return 0
}

rkhunter_clean=false
if command -v rkhunter >/dev/null 2>&1; then
  echo
  echo "── rkhunter (revisión antes de actualizar) ──"
  rk_report="$(mktemp)"
  if sudo rkhunter --check --skip-keypress --report-warnings-only 2>&1 | tee "${rk_report}"; then
    rkhunter_clean=true
  elif rkhunter_solo_paquetes "${rk_report}"; then
    echo "rkhunter: los avisos son solo de archivos de paquetes que coinciden con rpm -V; la base se actualiza tras dnf upgrade."
    rkhunter_clean=true
  else
    echo "rkhunter encontró avisos (/var/log/rkhunter/rkhunter.log): no se actualiza su base de referencia." >&2
    failed+=("rkhunter (avisos por revisar)")
  fi
  rm -f "${rk_report}"
fi

step "Paquetes DNF" sudo dnf upgrade --refresh -y

# Los de packages.txt que aún no estén, con las mismas opciones que
# fedora-install.sh. Solo se le pasan a dnf los que faltan: con todos, dnf
# avisaría por cada uno que ya está instalado.
install_new_packages() {
  local -a packages missing=()
  local package
  mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' "${scripts_dir}/../packages.txt")
  for package in "${packages[@]}"; do
    rpm -q "${package}" >/dev/null 2>&1 || missing+=("${package}")
  done
  if ((${#missing[@]} == 0)); then
    echo "Todos los paquetes de packages.txt están instalados."
    return
  fi
  sudo dnf install -y --setopt=exclude_from_weak='libretro-*' "${missing[@]}"
}
step "Paquetes nuevos de packages.txt" install_new_packages

if [[ "${rkhunter_clean}" == true ]]; then
  step "rkhunter (base de referencia)" sudo rkhunter --propupd --quiet
fi

# Firmware desde LVFS. Sin -y: grabar un firmware no se deshace, así que
# fwupdmgr pregunta por cada dispositivo (y antes de reiniciar, si hace falta).
# Devuelve 2 cuando no hay nada que hacer (metadatos al día o sin actualizaciones).
update_firmware() {
  local rc=0
  sudo fwupdmgr refresh || rc=$?
  ((rc == 0 || rc == 2)) || return "${rc}"
  rc=0
  sudo fwupdmgr update || rc=$?
  ((rc == 0 || rc == 2))
}
if command -v fwupdmgr >/dev/null 2>&1; then
  step "Firmware (fwupd)" update_firmware
fi

# fnm y cargo quedan en ~/.cargo/bin, que puede no estar aún en el PATH de este script
PATH="${HOME}/.cargo/bin:${PATH}"

# Node antes de los extras: los paquetes globales de npm viven en la versión
# predeterminada de fnm, y extras-install.sh los vuelve a instalar en la nueva
update_node() {
  local latest
  latest="$(fnm list-remote --latest)"
  fnm install "${latest}"
  fnm default "${latest}"
  echo "Node.js ${latest} predeterminado (las versiones anteriores siguen instaladas: fnm list)."
}
if command -v fnm >/dev/null 2>&1; then
  step "Node.js (última versión)" update_node
fi

# Solo los enlaces: el resto de dotfiles-install.sh volvería a cargar los ajustes
# de GNOME del repositorio sobre los del escritorio
step "Enlaces (dotfiles-install.sh --enlaces)" bash "${scripts_dir}/dotfiles-install.sh" --enlaces
step "Extras (extras-install.sh)" bash "${scripts_dir}/extras-install.sh"

if command -v composer >/dev/null 2>&1; then
  step "Composer global" composer global update --no-interaction
fi

if command -v pipx >/dev/null 2>&1; then
  step "pipx" pipx upgrade-all
fi

for editor in codium cursor; do
  if command -v "${editor}" >/dev/null 2>&1; then
    step "Extensiones de ${editor}" "${editor}" --update-extensions
  fi
done

step "Versiones fijas (check-versions.sh)" bash "${scripts_dir}/check-versions.sh"

steps_report "Todo actualizado."
