#!/usr/bin/env bash
set -euo pipefail

# Deshace los enlaces de dotfiles-install.sh: quita de $HOME cada enlace que apunte
# a este repositorio (los de scripts/lib/links.sh) y, si hay respaldos, restaura
# el más reciente (<archivo>.bak.<fecha>). Antes desactiva el timer del saludo
# matutino. No toca lo que no sea un enlace a este repositorio.
#
# No deshace el resto de fedora-install.sh ni de dotfiles-install.sh: paquetes,
# servicios, grupos, PostgreSQL, ajustes de GNOME y de Ptyxis, fuentes, la
# configuración de RetroArch, ~/.pgpass, allowed_signers ni npmrc-effective.
#
# Uso: dotfiles-uninstall.sh [--si]   (--si: sin pedir confirmación)

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=scripts/lib/links.sh
source "${repo_root}/scripts/lib/links.sh"
# shellcheck source=scripts/lib/backups.sh
source "${repo_root}/scripts/lib/backups.sh"

if [[ "${1:-}" != "--si" ]]; then
  if [[ ! -t 0 ]]; then
    echo "No hay una terminal para confirmar: debe usarse --si." >&2
    exit 1
  fi
  read -r -p "Se quitarán los enlaces de los dotfiles en ${HOME} y se restaurarán los respaldos. ¿Continuar? [s/N] " answer
  if [[ "${answer}" != [sS]* ]]; then
    echo "Cancelado."
    exit 0
  fi
fi

# ours <origen> <destino>: si ~/<destino> es un enlace a <origen> de este repositorio
ours() {
  [[ -L "${HOME}/$2" ]] && [[ "$(readlink "${HOME}/$2")" == "$(link_source "$1")" ]]
}

# El timer, antes de quitar sus unidades (systemctl --user requiere la sesión del usuario)
if ours systemd/buenos-dias.timer .config/systemd/user/buenos-dias.timer; then
  if systemctl --user disable --now buenos-dias.timer; then
    echo "Desactivado buenos-dias.timer"
  else
    echo "Advertencia: no se pudo desactivar buenos-dias.timer; debe hacerse a mano:" >&2
    echo "  systemctl --user disable --now buenos-dias.timer" >&2
  fi
fi

for entry in "${links[@]}"; do
  target="${HOME}/${entry#*:}"
  if ! ours "${entry%%:*}" "${entry#*:}"; then
    if [[ -e "${target}" ]] || [[ -L "${target}" ]]; then
      echo "Omitido   ~/${entry#*:} (no es un enlace a este repositorio)"
    fi
    continue
  fi
  rm "${target}"
  latest="$(backups_of "${target}" | head -n 1)"
  if [[ -n "${latest}" ]]; then
    mv "${latest}" "${target}"
    echo "Restaurado ~/${entry#*:} (desde ${latest##*/})"
  else
    echo "Quitado   ~/${entry#*:}"
  fi
done

systemctl --user daemon-reload 2>/dev/null || true
echo "Listo. Paquetes, servicios y ajustes de GNOME quedan como estaban (ver docs/mantenimiento.md)."
