#!/usr/bin/env bash
set -euo pipefail

# Genera /etc/minidlna.conf a partir de etc/minidlna.conf.in con los datos de
# este equipo y deja MiniDLNA compartiendo las carpetas XDG del usuario (Música,
# Vídeos e Imágenes):
# - interfaces físicas de NetworkManager (sin Docker ni libvirt), nombre con el
#   del usuario y del equipo, y serial derivado de /etc/machine-id;
# - acceso de solo lectura para el usuario minidlna con ACL (en el home, solo
#   para atravesarlo) y el booleano SELinux minidlna_read_generic_user_content;
# - «Compartir multimedia» de GNOME (Rygel) desactivado: sería un segundo servidor
#   DLNA con las mismas carpetas;
# - el servicio minidlna en firewalld (8200/tcp y 1900/udp), solo en la zona de
#   casa (scripts/lib/zones.sh);
# - el servicio habilitado; se reinicia si cambió la configuración.
# Lo ejecuta fedora-install.sh; puede ejecutarse varias veces (sin sudo).
#
# Uso: install-minidlna.sh [--mostrar]   (--mostrar: solo muestra la configuración)

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template="${repo_root}/etc/minidlna.conf.in"
config="/etc/minidlna.conf"

# shellcheck source=scripts/lib/backups.sh
source "${repo_root}/scripts/lib/backups.sh"
# shellcheck source=scripts/lib/zones.sh
source "${repo_root}/scripts/lib/zones.sh"

if ! rpm -q minidlna >/dev/null 2>&1; then
  echo "No está instalado minidlna (packages.txt)." >&2
  exit 1
fi

# ── Datos del equipo ──────────────────────────────────────────────────────────
# Ethernet y Wi-Fi administradas por NetworkManager (los veth de Docker figuran
# como ethernet, pero sin administrar), más lo. MiniDLNA admite hasta 8.
mapfile -t interfaces < <(
  echo lo
  nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null |
    awk -F: '($2 == "ethernet" || $2 == "wifi") && $3 != "unmanaged" {print $1}'
)
network_interface="$(printf '%s\n' "${interfaces[@]:0:8}" | paste -sd, -)"

first_name="$(getent passwd "${USER}" | cut -d: -f5 | cut -d, -f1 | awk '{print $1}')"
friendly_name="Servidor DLNA de ${first_name:-${USER}} ($(hostnamectl --static 2>/dev/null || hostname -s))"

machine_id="$(cat /etc/machine-id)"
serial="$((16#${machine_id:0:8}))"

xdg_dir() {
  local dir
  dir="$(xdg-user-dir "$1" 2>/dev/null || true)"
  # Sin carpeta XDG configurada, xdg-user-dir devuelve el home
  if [[ -z "${dir}" || "${dir}" == "${HOME}" ]]; then
    dir="${HOME}/$2"
  fi
  echo "${dir}"
}
media_music="$(xdg_dir MUSIC Música)"
media_videos="$(xdg_dir VIDEOS Vídeos)"
media_pictures="$(xdg_dir PICTURES Imágenes)"

# ── Configuración ─────────────────────────────────────────────────────────────
# El primer bloque de comentarios (hasta la primera línea vacía) describe la
# plantilla; en /etc va un encabezado que avisa que el archivo es generado
content="$(<"${template}")"
content="# Generado por scripts/install-minidlna.sh (dotfiles) a partir de etc/minidlna.conf.in.
# No debe editarse aquí: se reemplaza al volver a ejecutar el script.

${content#*$'\n\n'}"
# Reemplazos entre comillas: sin ellas, bash 5.2 cambia & por el marcador
content="${content//@NETWORK_INTERFACE@/"${network_interface}"}"
content="${content//@FRIENDLY_NAME@/"${friendly_name}"}"
content="${content//@SERIAL@/"${serial}"}"
content="${content//@MEDIA_MUSIC@/"${media_music}"}"
content="${content//@MEDIA_VIDEOS@/"${media_videos}"}"
content="${content//@MEDIA_PICTURES@/"${media_pictures}"}"
if [[ "${content}" == *@[A-Z_]*@* ]]; then
  echo "Quedó un marcador sin reemplazar en ${template}." >&2
  exit 1
fi

if [[ "${1:-}" == "--mostrar" ]]; then
  printf '%s\n' "${content}"
  exit 0
fi

# ── Sin «Compartir multimedia» de GNOME ───────────────────────────────────────
# Es otro servidor DLNA (Rygel) con las mismas carpetas: los clientes verían dos.
# Se desactiva como lo hace Configuración, en cada red donde estaba activo (D-Bus
# de gnome-settings-daemon, que también detiene Rygel); sin sesión de GNOME, se
# vacía directamente la lista de redes.
rygel_schema="org.gnome.settings-daemon.plugins.sharing.service:/org/gnome/settings-daemon/plugins/sharing/rygel/"
if gsettings list-relocatable-schemas 2>/dev/null | grep -qx org.gnome.settings-daemon.plugins.sharing.service; then
  mapfile -t rygel_networks < <(gsettings get "${rygel_schema}" enabled-connections | grep -oE "'[^']+'" | tr -d "'")
  for network in "${rygel_networks[@]}"; do
    gdbus call --session --dest org.gnome.SettingsDaemon.Sharing --object-path /org/gnome/SettingsDaemon/Sharing \
      --method org.gnome.SettingsDaemon.Sharing.DisableService rygel "${network}" >/dev/null 2>&1 || true
  done
  gsettings set "${rygel_schema}" enabled-connections "[]"
  if ((${#rygel_networks[@]} > 0)); then
    echo "Rygel     desactivado «Compartir multimedia» de GNOME (lo reemplaza MiniDLNA)"
  fi
fi

changed=false
if [[ "$(cat "${config}" 2>/dev/null)" == "${content}" ]]; then
  echo "Correcto  ${config}"
else
  if [[ -e "${config}" ]]; then
    sudo cp -p "${config}" "${config}${backup_suffix}"
    echo "Respaldo  ${config} -> ${config}${backup_suffix}"
  fi
  printf '%s\n' "${content}" | sudo tee "${config}" >/dev/null
  sudo chmod 644 "${config}"
  echo "Generado  ${config} (interfaces: ${network_interface})"
  changed=true
fi
prune_backups "${config}" sudo

# ── Permisos ──────────────────────────────────────────────────────────────────
# El home es 700: minidlna solo puede atravesarlo (x), no listarlo. En las carpetas
# de medios, lectura para lo que ya hay y, por defecto, para lo que se agregue.
setfacl -m u:minidlna:x "${HOME}"
for dir in "${media_music}" "${media_videos}" "${media_pictures}"; do
  mkdir -p "${dir}"
  setfacl -R -m u:minidlna:rX "${dir}"
  find "${dir}" -type d -exec setfacl -d -m u:minidlna:rX {} +
done
echo "Permisos  lectura para minidlna en ${media_music}, ${media_videos} y ${media_pictures}"

if [[ "$(getsebool minidlna_read_generic_user_content 2>/dev/null)" == *"--> off" ]]; then
  sudo setsebool -P minidlna_read_generic_user_content on
  echo "SELinux   minidlna_read_generic_user_content activado"
fi

# ── Firewall y servicio ───────────────────────────────────────────────────────
# Solo en la zona de casa, no en la de la interfaz: ejecutado fuera de casa, la
# Wi-Fi estaría en la zona public y MiniDLNA quedaría anunciado en una red ajena.
if systemctl is-active --quiet firewalld; then
  if ! sudo firewall-cmd --permanent --zone="${zone_home}" --query-service=minidlna >/dev/null; then
    sudo firewall-cmd --permanent --zone="${zone_home}" --add-service=minidlna >/dev/null
    echo "Firewall  servicio minidlna abierto en la zona ${zone_home} (8200/tcp, 1900/udp)"
    sudo firewall-cmd --reload >/dev/null
  fi
else
  echo "Advertencia: firewalld no está activo; no se abrió el servicio minidlna." >&2
fi

sudo systemctl enable --now minidlna
if [[ "${changed}" == true ]]; then
  sudo systemctl restart minidlna
fi
echo "MiniDLNA activo como «${friendly_name}» en http://localhost:8200/"
