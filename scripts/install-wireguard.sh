#!/usr/bin/env bash
set -euo pipefail

# Conecta el equipo a la VPN de Sea Dragon (WireGuard) con NetworkManager, siempre
# activa pero solo para lo que vive detrás de ella (split tunnel):
# - La configuración viene de Nextcloud, Importante/VPN/<hostname>-vpn.conf: un
#   archivo por equipo (cada uno con su par de claves), generado por el servidor.
#   Lleva la clave privada, así que no está en el repositorio y se deja en 600.
# - Antes de importarla, revisa que AllowedIPs no lleve la ruta por defecto
#   (0.0.0.0/0, ::/0 o sus mitades /1): todo el tráfico saldría por la VPN. Exige
#   DNS (el DNS del servidor dentro de la VPN) y avisa si falta
#   PersistentKeepalive (sin él, el túnel se corta detrás de NAT).
# - Solo los nombres de vpn_domains se resuelven con ese DNS (dominios de ruteo
#   de systemd-resolved, ~dominio); el resto de las consultas y del tráfico sigue
#   por la conexión normal.
# - Se conecta sola al arrancar (connection.autoconnect).
# - Vuelve a importar solo si el archivo cambió (su sha256 queda en
#   ~/.local/state/dotfiles); si no, solo revisa los ajustes de arriba.
# Lo ejecuta dotfiles-install.sh (también con --enlaces, así que también
# dotfiles-update.sh); puede ejecutarse solo y varias veces. Si Nextcloud no
# tiene el archivo de este equipo, avisa y termina sin error.
#
# Uso: install-wireguard.sh [--mostrar]   (--mostrar: solo muestra los cambios)

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/nextcloud.sh
source "${repo_root}/scripts/lib/nextcloud.sh"

vpn_name="Sea Dragon VPN"
# Nombre de la interfaz: NetworkManager la nombra como el archivo importado (máximo
# 15 caracteres)
vpn_interface="wg-seadragon"
# Lo único que se resuelve (y se alcanza) por la VPN
vpn_domains=(vault.seadragon.cl git.seadragon.cl cockpit.seadragon.cl)

show=false
case "${1:-}" in
"") ;;
--mostrar) show=true ;;
*)
  echo "Uso: install-wireguard.sh [--mostrar]" >&2
  exit 1
  ;;
esac

if ! command -v nmcli >/dev/null 2>&1; then
  echo "Advertencia: no está nmcli (NetworkManager); no se configuró la VPN." >&2
  exit 0
fi

host="$(hostnamectl --static 2>/dev/null || hostname -s)"
vpn_remote="Importante/VPN/${host}-vpn.conf"
if ! conf="$(nextcloud_path "${vpn_remote}")"; then
  echo "Advertencia: ${vpn_remote} no está sincronizado; no se configuró la VPN." >&2
  exit 0
fi

# Las consultas, en inglés: los valores (yes/no) no dependen del idioma
nm() {
  LC_ALL=C nmcli "$@"
}

# ── Revisar el archivo ────────────────────────────────────────────────────────
allowed_ips=()
dns=""
keepalive=""
while IFS='=' read -r key value; do
  key="${key//[[:space:]]/}"
  value="${value//[[:space:]]/}"
  case "${key,,}" in
  allowedips) IFS=',' read -ra ips <<<"${value}" && allowed_ips+=("${ips[@]}") ;;
  dns) dns="${value}" ;;
  persistentkeepalive) keepalive="${value}" ;;
  esac
done <"${conf}"

if ((${#allowed_ips[@]} == 0)); then
  echo "Error: ${vpn_remote} no tiene AllowedIPs." >&2
  exit 1
fi
for ip in "${allowed_ips[@]}"; do
  if [[ "${ip}" == */0 || "${ip}" == */1 ]]; then
    echo "Error: ${vpn_remote} manda todo el tráfico por la VPN (AllowedIPs = ${ip})." >&2
    echo "  Debe llevar solo las direcciones de la VPN (por ejemplo, 10.8.0.1/32)." >&2
    exit 1
  fi
done
if [[ -z "${dns}" ]]; then
  echo "Error: ${vpn_remote} no tiene DNS (el DNS del servidor dentro de la VPN)." >&2
  exit 1
fi
if [[ -z "${keepalive}" || "${keepalive}" == 0 ]]; then
  echo "Advertencia: ${vpn_remote} no tiene PersistentKeepalive; detrás de NAT el túnel puede cortarse." >&2
fi

# El cliente de Nextcloud baja los archivos con 644
if [[ "$(stat -c %a "${conf}")" != 600 ]]; then
  if [[ "${show}" == true ]]; then
    echo "Cambiaría ${vpn_remote} a permisos 600"
  else
    chmod 600 "${conf}"
    echo "Permisos  ${vpn_remote} en 600 (lleva la clave privada)"
  fi
fi

# ── Importar ──────────────────────────────────────────────────────────────────
state_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/dotfiles"
state_file="${state_dir}/wireguard.sha256"
sha="$(sha256sum "${conf}" | cut -d' ' -f1)"
exists=false
if [[ "$(nm -g connection.type connection show "${vpn_name}" 2>/dev/null)" == wireguard ]]; then
  exists=true
fi
changed=false

if [[ "${exists}" == true && -f "${state_file}" && "$(<"${state_file}")" == "${sha}" ]]; then
  echo "Correcto  conexión «${vpn_name}» al día con ${vpn_remote}"
elif [[ "${show}" == true ]]; then
  echo "Importaría ${vpn_remote} como la conexión «${vpn_name}»"
  # Sin conexión no hay ajustes que revisar
  [[ "${exists}" == true ]] || exit 0
else
  if [[ "${exists}" == true ]]; then
    sudo nmcli connection delete "${vpn_name}" >/dev/null
  fi
  # Una copia con el nombre de la interfaz, en un directorio que solo lee el usuario
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' EXIT
  install -m 600 "${conf}" "${tmp_dir}/${vpn_interface}.conf"
  sudo nmcli connection import type wireguard file "${tmp_dir}/${vpn_interface}.conf" >/dev/null
  rm -rf "${tmp_dir}"
  sudo nmcli connection modify "${vpn_interface}" connection.id "${vpn_name}"
  install -d -m 700 "${state_dir}"
  echo "${sha}" >"${state_file}"
  echo "Importada ${vpn_remote} como la conexión «${vpn_name}» (interfaz ${vpn_interface})"
  exists=true
  changed=true
fi

# ── Ajustes ───────────────────────────────────────────────────────────────────
# nmcli muestra la lista de dominios separada por comas
dns_search="$(printf '~%s,' "${vpn_domains[@]}")"
dns_search="${dns_search%,}"

# setting <propiedad> <valor> <descripción>
setting() {
  if [[ "$(nm -g "$1" connection show "${vpn_name}")" == "$2" ]]; then
    echo "Correcto  ${3}"
  elif [[ "${show}" == true ]]; then
    echo "Cambiaría ${3}"
  else
    sudo nmcli connection modify "${vpn_name}" "$1" "$2"
    echo "VPN       ${3}"
    changed=true
  fi
}

setting connection.autoconnect yes "conexión automática al arrancar"
setting ipv4.dns-search "${dns_search}" "DNS de la VPN solo para ${vpn_domains[*]}"

# ── Activar ───────────────────────────────────────────────────────────────────
active=false
if nm -g NAME connection show --active | grep -qxF "${vpn_name}"; then
  active=true
fi
if [[ "${active}" == true && "${changed}" == false ]]; then
  echo "Correcto  VPN activa"
elif [[ "${show}" == true ]]; then
  echo "Activaría la VPN"
elif sudo nmcli connection up "${vpn_name}" >/dev/null; then
  echo "Activada  VPN «${vpn_name}»"
else
  echo "Advertencia: no se pudo activar la VPN; revisa nmcli connection up \"${vpn_name}\"." >&2
fi
