#!/usr/bin/env bash
set -euo pipefail

# Actualiza en un solo comando todo lo que instalan estos dotfiles:
# - los paquetes DNF (packages.txt y el resto del sistema), con rkhunter antes
#   (revisión) y después (base de referencia, si la revisión no tuvo avisos), y
#   los que se agregaron a packages.txt desde la última vez;
# - los enlaces nuevos de scripts/lib/links.sh (dotfiles-install.sh --enlaces);
# - el firmware, con fwupd (pide confirmación por cada dispositivo);
# - lo de extras-install.sh: rustup, fnm, oh-my-zsh y los plugins de zsh y tmux,
#   los crates de Cargo, los plugins de Vim (YouCompleteMe se recompila si cambió)
#   los programas compilados en versión fija (solo si cambió la versión) y
#   opencode (Zed se actualiza solo);
# - Node.js: la última versión con fnm, que queda como predeterminada;
# - pipx (piper-tts, sqlmap) y las extensiones de VSCodium y Cursor;
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
# Solo si no hay avisos se actualiza la base después de dnf upgrade (si no, cada
# archivo que cambia una actualización sería un aviso); con avisos, la base queda
# como estaba, para no aceptar un cambio ajeno a las actualizaciones.
rkhunter_clean=false
if command -v rkhunter >/dev/null 2>&1; then
  echo
  echo "── rkhunter (revisión antes de actualizar) ──"
  if sudo rkhunter --check --skip-keypress --report-warnings-only; then
    rkhunter_clean=true
  else
    echo "rkhunter encontró avisos (/var/log/rkhunter/rkhunter.log): no se actualiza su base de referencia." >&2
    failed+=("rkhunter (avisos por revisar)")
  fi
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

# Solo los enlaces: el resto de dotfiles-install.sh volvería a cargar los ajustes
# de GNOME del repositorio sobre los del escritorio
step "Enlaces (dotfiles-install.sh --enlaces)" bash "${scripts_dir}/dotfiles-install.sh" --enlaces
step "Extras (extras-install.sh)" bash "${scripts_dir}/extras-install.sh"

# fnm y cargo quedan en ~/.cargo/bin, que puede no estar aún en el PATH de este script
PATH="${HOME}/.cargo/bin:${PATH}"

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
