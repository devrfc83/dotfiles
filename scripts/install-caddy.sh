#!/usr/bin/env bash
set -euo pipefail

# Caddy como proxy inverso local con HTTPS para los servidores de desarrollo
# (Vite, php artisan serve, Reverb, Mailpit), con los nombres de
# etc/caddy/Caddyfile (*.lvh.me, que resuelven a 127.0.0.1 en el DNS público):
# - la autoridad local de mkcert, en el almacén del sistema (pide sudo) y en el
#   de Chrome (NSS, con certutil de nss-tools): los certificados valen solo en
#   este equipo;
# - el certificado de *.lvh.me en /etc/caddy/certs, legible por el usuario caddy;
#   se renueva si falta, si vence en menos de 30 días o si lo firmó otra autoridad;
# - /etc/caddy/Caddyfile, reemplazado por el del repositorio una vez validado
#   (el anterior se respalda);
# - los nombres del Caddyfile en /etc/hosts, en un bloque propio, para que
#   funcionen sin conexión (lvh.me es un dominio real);
# - el servicio habilitado, recargado si algo cambió. Caddy escucha solo en
#   127.0.0.1 (default_bind), así que no se toca el firewall.
# Requiere caddy, mkcert y nss-tools (packages.txt). Lo ejecuta fedora-install.sh;
# puede ejecutarse varias veces (sin sudo). Para agregar un nombre, se edita
# etc/caddy/Caddyfile y se vuelve a ejecutar.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
caddyfile_src="${repo_root}/etc/caddy/Caddyfile"
caddyfile="/etc/caddy/Caddyfile"
certs_dir="/etc/caddy/certs"
cert="${certs_dir}/lvh.me.pem"
key="${certs_dir}/lvh.me-key.pem"
hosts_file="/etc/hosts"
hosts_begin="# dotfiles: Caddy (scripts/install-caddy.sh), inicio"
hosts_end="# dotfiles: Caddy, fin"

# shellcheck source=scripts/lib/backups.sh
source "${repo_root}/scripts/lib/backups.sh"

# La autoridad de mkcert es del usuario que ejecuta el script (su ~/.local/share
# y el almacén NSS de su Chrome)
if ((EUID == 0)); then
  echo "Este script debe ejecutarse como usuario normal, sin sudo." >&2
  exit 1
fi

for package in caddy mkcert nss-tools; do
  if ! rpm -q "${package}" >/dev/null 2>&1; then
    echo "No está instalado ${package} (packages.txt)." >&2
    exit 1
  fi
done

changed=false

# ── Autoridad local de mkcert ─────────────────────────────────────────────────
# Si ya está en los dos almacenes, mkcert no hace nada. Chrome crea su almacén
# (~/.pki/nssdb) la primera vez que se abre: si aún no existe, mkcert lo avisa y
# debe volver a ejecutarse este script después.
echo "Configurando la autoridad local de mkcert..."
mkcert -install

# ── Certificado de *.lvh.me ───────────────────────────────────────────────────
cert_ok=false
if [[ -f "${cert}" ]] && sudo test -f "${key}" &&
  openssl x509 -in "${cert}" -noout -checkend $((30 * 24 * 3600)) >/dev/null &&
  openssl verify -CAfile "$(mkcert -CAROOT)/rootCA.pem" "${cert}" >/dev/null 2>&1; then
  cert_ok=true
fi
if [[ "${cert_ok}" == true ]]; then
  echo "Correcto  ${cert}"
else
  work_dir="$(mktemp -d)"
  trap 'rm -rf "${work_dir}"' EXIT
  mkcert -cert-file "${work_dir}/cert.pem" -key-file "${work_dir}/key.pem" "*.lvh.me" lvh.me >/dev/null 2>&1
  # La llave solo la lee el grupo caddy
  sudo install -D -m 644 -o root -g caddy "${work_dir}/cert.pem" "${cert}"
  sudo install -D -m 640 -o root -g caddy "${work_dir}/key.pem" "${key}"
  echo "Generado  ${cert} (*.lvh.me, mkcert; vence $(openssl x509 -in "${cert}" -noout -enddate | cut -d= -f2))"
  changed=true
fi

# ── Caddyfile ─────────────────────────────────────────────────────────────────
# Se valida el del repositorio antes de instalarlo (como root: lee la llave)
if ! sudo caddy validate --config "${caddyfile_src}" --adapter caddyfile >/dev/null 2>&1; then
  echo "etc/caddy/Caddyfile no es válido:" >&2
  sudo caddy validate --config "${caddyfile_src}" --adapter caddyfile >&2 || true
  exit 1
fi
if sudo cmp -s "${caddyfile_src}" "${caddyfile}"; then
  echo "Correcto  ${caddyfile}"
else
  if sudo test -f "${caddyfile}"; then
    sudo cp -p "${caddyfile}" "${caddyfile}${backup_suffix}"
    echo "Respaldo  ${caddyfile} -> ${caddyfile}${backup_suffix}"
  fi
  sudo install -m 644 "${caddyfile_src}" "${caddyfile}"
  echo "Generado  ${caddyfile} (etc/caddy/Caddyfile)"
  changed=true
fi
prune_backups "${caddyfile}" sudo

# ── /etc/hosts ────────────────────────────────────────────────────────────────
# Los nombres de los bloques de sitio del Caddyfile, en un bloque entre marcas
# que se reemplaza entero; el resto del archivo no se toca
mapfile -t names < <(grep -oE '^[a-z0-9.-]+\.lvh\.me' "${caddyfile_src}" | sort -u)
hosts_rest="$(awk -v begin="${hosts_begin}" -v end="${hosts_end}" '
  $0 == begin { skip = 1 }
  !skip { print }
  $0 == end { skip = 0 }
' "${hosts_file}")"
hosts_new="$(printf '%s\n\n%s\n127.0.0.1 %s\n%s\n' "${hosts_rest%"${hosts_rest##*[![:space:]]}"}" \
  "${hosts_begin}" "${names[*]}" "${hosts_end}")"
if [[ "$(cat "${hosts_file}")" == "${hosts_new}" ]]; then
  echo "Correcto  ${hosts_file} (${#names[@]} nombres)"
else
  sudo cp -p "${hosts_file}" "${hosts_file}${backup_suffix}"
  printf '%s\n' "${hosts_new}" | sudo tee "${hosts_file}" >/dev/null
  echo "Generado  bloque de Caddy en ${hosts_file} (${names[*]})"
fi
prune_backups "${hosts_file}" sudo

# ── Servicio ──────────────────────────────────────────────────────────────────
sudo systemctl enable --now caddy
if [[ "${changed}" == true ]]; then
  sudo systemctl reload caddy
fi
echo "Caddy     activo en 127.0.0.1 (80 y 443):"
printf '          https://%s\n' "${names[@]}"
