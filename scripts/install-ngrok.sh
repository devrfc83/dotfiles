#!/usr/bin/env bash
set -euo pipefail

# ngrok (túneles: publica en Internet un puerto de este equipo con una URL
# https://…ngrok-free.app o un dominio propio) no está en Fedora ni tiene un
# repositorio RPM público: se instala el binario de su descarga, en una versión
# fija y con su sha256, en ~/.local/bin/ngrok. Si ya está esa versión, no hace
# nada. Lo ejecuta extras-install.sh.
#
# No se levanta nada: un túnel expone un puerto a Internet, así que se abre a mano
# (ngrok http 3000). La cuenta y el token no van en el repositorio: se guardan con
# ngrok config add-authtoken, en ~/.config/ngrok/ngrok.yml, o en ~/.zshsecrets.
#
# Para actualizar, deben cambiarse version y sha256 (la descarga versionada es
# la misma que la estable); check-versions.sh avisa cuando hay una nueva.

version="3.39.13"
sha256="233e0647849913e6404150c1e9c5e4f31c1368aefee330958d038d7afecb8f2e"
url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-${version}-linux-amd64.tgz"
bin="${HOME}/.local/bin/ngrok"
version_file="${HOME}/.local/share/ngrok/version"

if [[ -x "${bin}" ]] && [[ "$(cat "${version_file}" 2>/dev/null)" == "${version}" ]]; then
  echo "ngrok ${version} ya está instalado."
  exit 0
fi

echo "Instalando ngrok ${version}..."
download_dir="$(mktemp -d)"
trap 'rm -rf "${download_dir}"' EXIT

curl --proto '=https' --tlsv1.2 -sSfL -o "${download_dir}/ngrok.tgz" "${url}"
echo "${sha256}  ${download_dir}/ngrok.tgz" | sha256sum -c --quiet
tar -C "${download_dir}" -xzf "${download_dir}/ngrok.tgz" ngrok

install -D -m 755 "${download_dir}/ngrok" "${bin}"
install -d "$(dirname "${version_file}")"
echo "${version}" >"${version_file}"
echo "ngrok ${version} instalado en ${bin}."
