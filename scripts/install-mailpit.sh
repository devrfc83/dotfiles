#!/usr/bin/env bash
set -euo pipefail

# Mailpit (correo de desarrollo: recibe por SMTP lo que mandan las aplicaciones y
# lo muestra en una interfaz web) no está en Fedora: se instala el binario de los
# releases del upstream, en una versión fija y con su sha256, en
# ~/.local/bin/mailpit, y se habilita systemd/mailpit.service (unidad de usuario
# que enlaza dotfiles-install.sh; SMTP en 127.0.0.1:1025, web en 127.0.0.1:8025,
# también como https://mailpit.lvh.me por Caddy). Si ya está esa versión, solo
# comprueba el servicio. Lo ejecuta extras-install.sh.
#
# Para actualizar, deben cambiarse version y sha256 (el upstream no publica el
# checksum: se calcula con sha256sum sobre mailpit-linux-amd64.tar.gz);
# check-versions.sh avisa cuando hay una versión nueva.

version="1.33.1"
sha256="84d7fe375ebef25df26758984dc0d5d5e17d8c0734cb2e77be7873b14ab51716"
repo_url="https://github.com/axllent/mailpit.git"
archive="mailpit-linux-amd64.tar.gz"
archive_url="${repo_url%.git}/releases/download/v${version}/${archive}"
bin="${HOME}/.local/bin/mailpit"
data_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/mailpit"
version_file="${data_dir}/version"
unit="${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user/mailpit.service"

# El servicio requiere la sesión del usuario y la unidad enlazada (scripts/lib/links.sh)
enable_service() {
  if [[ ! -f "${unit}" ]]; then
    echo "Advertencia: no está enlazada mailpit.service; debe ejecutarse dotfiles-install.sh." >&2
    return
  fi
  if systemctl --user daemon-reload && systemctl --user enable --now mailpit.service; then
    echo "Activado  mailpit.service (SMTP 127.0.0.1:1025, web http://localhost:8025)"
  else
    echo "Advertencia: no se pudo activar mailpit.service; debe ejecutarse a mano:" >&2
    echo "  systemctl --user enable --now mailpit.service" >&2
  fi
}

if [[ -x "${bin}" ]] && [[ "$(cat "${version_file}" 2>/dev/null)" == "${version}" ]]; then
  echo "Mailpit ${version} ya está instalado."
  enable_service
  exit 0
fi

echo "Instalando Mailpit ${version}..."
download_dir="$(mktemp -d)"
trap 'rm -rf "${download_dir}"' EXIT

curl --proto '=https' --tlsv1.2 -sSfL -o "${download_dir}/${archive}" "${archive_url}"
echo "${sha256}  ${download_dir}/${archive}" | sha256sum -c --quiet
tar -C "${download_dir}" -xzf "${download_dir}/${archive}" mailpit

install -D -m 755 "${download_dir}/mailpit" "${bin}"
install -d "${data_dir}"
echo "${version}" >"${version_file}"
echo "Mailpit ${version} instalado en ${bin}."

enable_service
# Con el binario nuevo, si ya estaba en marcha
systemctl --user try-restart mailpit.service 2>/dev/null || true
