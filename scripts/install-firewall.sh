#!/usr/bin/env bash
set -euo pipefail

# Reparte firewalld en dos zonas (scripts/lib/zones.sh):
# - Casa (FedoraWorkstation), para las conexiones marcadas con --casa. De fábrica
#   permite todos los puertos del 1025 al 65535, TCP y UDP: todo lo que escuche en
#   todas las interfaces queda accesible en la red (un servidor de desarrollo...).
#   Aquí se quita ese rango y se permite solo lo que usan los servicios de
#   Configuración → Compartir que estén instalados:
#   - Escritorio remoto (gnome-remote-desktop): 3389/tcp (inicio de sesión remoto)
#     y 3390/tcp (compartir el escritorio de la sesión, que negocia el siguiente
#     puerto libre).
#   - Compartir archivos personales (gnome-user-share, WebDAV), solo si está
#     activado en alguna conexión: su puerto es aleatorio, del rango efímero del
#     kernel (net.ipv4.ip_local_port_range, 32768-60999), y no se puede fijar; se
#     permite ese rango, solo TCP. Desactivado, el rango se cierra.
#   - Descubrimiento en la red: mDNS (avahi), LLMNR, WS-Discovery (wsdd) y las
#     respuestas de UPnP/SSDP.
#   - 8000/tcp: el alias www (zsh/zshaliases), para probar sitios desde el móvil.
#   Los servicios que ya tenía la zona (ssh, samba-client, minidlna...) se quedan.
# - Fuera de casa (public): la zona por defecto, así que toda conexión sin zona
#   propia (una red nueva o ajena) queda en ella. Se le quita ssh: sshd solo
#   responde en casa.
# Lo ejecuta fedora-install.sh, después de install-minidlna.sh; puede ejecutarse
# varias veces (sin sudo). Debe ejecutarse de nuevo al activar o desactivar
# Compartir archivos.
#
# Uso: install-firewall.sh [--mostrar] [--casa <conexión>]...
#   --mostrar          solo muestra los cambios
#   --casa <conexión>  marca una conexión de NetworkManager (nombre o UUID) como
#                      de casa; puede repetirse

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/zones.sh
source "${repo_root}/scripts/lib/zones.sh"

usage="Uso: install-firewall.sh [--mostrar] [--casa <conexión>]..."
show=false
home_connections=()
while (($# > 0)); do
  case "$1" in
  --mostrar) show=true ;;
  --casa)
    if (($# < 2)); then
      echo "${usage}" >&2
      exit 1
    fi
    home_connections+=("$2")
    shift
    ;;
  *)
    echo "${usage}" >&2
    exit 1
    ;;
  esac
  shift
done

if ! systemctl is-active --quiet firewalld; then
  echo "Advertencia: firewalld no está activo; no se cambiaron las zonas." >&2
  exit 0
fi

# Las consultas no requieren root; los cambios, sí (con --mostrar solo se muestran)
fw() {
  firewall-cmd "$@"
}

changes=0

# change <zona> <descripción> <argumentos de firewall-cmd>
change() {
  local zone="$1" description="$2"
  shift 2
  if [[ "${show}" == true ]]; then
    echo "Cambiaría ${description} (zona ${zone})"
  else
    sudo firewall-cmd --permanent --zone="${zone}" "$@" >/dev/null
    echo "Firewall  ${description} (zona ${zone})"
  fi
  changes=$((changes + 1))
}

# has_port <zona> <puerto>: si la zona tiene exactamente esa entrada
# (--query-port también responde sí para un puerto dentro de un rango)
has_port() {
  fw --permanent --zone="$1" --list-ports | tr ' ' '\n' | grep -qxF "$2"
}

# Si Compartir archivos personales está activado en alguna conexión (GNOME lo
# guarda por conexión, en la configuración de gsd-sharing)
webdav_enabled() {
  local enabled
  enabled="$(gsettings get \
    org.gnome.settings-daemon.plugins.sharing.service:/org/gnome/settings-daemon/plugins/sharing/gnome-user-share-webdav/ \
    enabled-connections 2>/dev/null || true)"
  [[ -n "${enabled}" ]] && [[ "${enabled}" != "@as []" ]]
}

# ── Casa ──────────────────────────────────────────────────────────────────────
for range in 1025-65535/tcp 1025-65535/udp; do
  if has_port "${zone_home}" "${range}"; then
    change "${zone_home}" "quitar el rango ${range}" --remove-port="${range}"
  fi
done

services=(mdns llmnr llmnr-client wsdd ws-discovery-client upnp-client)
# El alias www de zsh/zshaliases (python -m http.server 8000), para probar sitios
# desde el móvil
ports=(8000/tcp)
if rpm -q gnome-remote-desktop >/dev/null 2>&1; then
  services+=(rdp)
  ports+=(3390/tcp)
fi
read -r ephemeral_from ephemeral_to </proc/sys/net/ipv4/ip_local_port_range
ephemeral="${ephemeral_from}-${ephemeral_to}/tcp"
if rpm -q gnome-user-share >/dev/null 2>&1 && webdav_enabled; then
  ports+=("${ephemeral}")
elif has_port "${zone_home}" "${ephemeral}"; then
  change "${zone_home}" "cerrar el rango ${ephemeral} (Compartir archivos no está activado)" \
    --remove-port="${ephemeral}"
fi

for service in "${services[@]}"; do
  if ! fw --permanent --zone="${zone_home}" --query-service="${service}" >/dev/null; then
    change "${zone_home}" "permitir el servicio ${service}" --add-service="${service}"
  fi
done
for port in "${ports[@]}"; do
  if ! has_port "${zone_home}" "${port}"; then
    change "${zone_home}" "permitir el puerto ${port}" --add-port="${port}"
  fi
done

# ── Fuera de casa ─────────────────────────────────────────────────────────────
if fw --permanent --zone="${zone_away}" --query-service=ssh >/dev/null; then
  change "${zone_away}" "quitar el servicio ssh" --remove-service=ssh
fi

if ((changes > 0)) && [[ "${show}" == false ]]; then
  sudo firewall-cmd --reload >/dev/null
  echo "Firewall  zonas recargadas"
fi

# ── Conexiones de casa ────────────────────────────────────────────────────────
# Antes de cambiar la zona por defecto: así una conexión de casa activa no pasa
# por la de fuera. reapply aplica la zona nueva sin desconectar.
for connection in "${home_connections[@]}"; do
  if ! current="$(nmcli -g connection.zone connection show "${connection}" 2>/dev/null)"; then
    echo "No existe la conexión «${connection}» (nmcli connection show)." >&2
    exit 1
  fi
  if [[ "${current}" == "${zone_home}" ]]; then
    echo "Correcto  conexión «${connection}» en la zona ${zone_home}"
  elif [[ "${show}" == true ]]; then
    echo "Cambiaría la conexión «${connection}» a la zona ${zone_home}"
  else
    sudo nmcli connection modify "${connection}" connection.zone "${zone_home}"
    device="$(nmcli -g GENERAL.DEVICES connection show "${connection}" 2>/dev/null || true)"
    if [[ -n "${device}" ]]; then
      sudo nmcli device reapply "${device}" >/dev/null
    fi
    echo "Conexión  «${connection}» en la zona ${zone_home} (casa)"
  fi
done

# ── Zona por defecto ──────────────────────────────────────────────────────────
if [[ "$(fw --get-default-zone)" == "${zone_away}" ]]; then
  echo "Correcto  zona por defecto ${zone_away}"
elif [[ "${show}" == true ]]; then
  echo "Cambiaría la zona por defecto a ${zone_away}"
else
  # Permanente y en ejecución a la vez (no admite --permanent)
  sudo firewall-cmd --set-default-zone="${zone_away}" >/dev/null
  echo "Firewall  zona por defecto ${zone_away} (fuera de casa)"
fi

# Sin ninguna conexión de casa, todas quedan fuera de casa (con --mostrar y
# --casa, las conexiones aún no cambian)
home_found=false
if [[ "${show}" == true ]] && ((${#home_connections[@]} > 0)); then
  home_found=true
fi
while IFS= read -r uuid; do
  if [[ "$(nmcli -g connection.zone connection show "${uuid}" 2>/dev/null)" == "${zone_home}" ]]; then
    home_found=true
    break
  fi
done < <(nmcli -g UUID connection show 2>/dev/null)
if [[ "${home_found}" == false ]]; then
  echo "Advertencia: ninguna conexión está marcada como de casa; todas usan la zona ${zone_away}." >&2
  echo "  Para marcar la de casa: bash scripts/install-firewall.sh --casa \"<conexión>\"" >&2
fi
