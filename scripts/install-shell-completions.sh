#!/usr/bin/env bash
set -euo pipefail

# Completados de zsh de las herramientas instaladas a mano que no los traen con su
# paquete: Bitwarden (bw), ngrok y Mailpit. Cada una genera su función _<orden> en
# ~/.local/share/zsh/site-functions, que zsh/zshrc agrega a fpath. Se regeneran en
# cada ejecución, así que una versión nueva actualiza su completado. Las demás
# herramientas (delta, yq, uv, trivy, gh...) lo traen con su paquete. Lo ejecuta
# extras-install.sh, después de las herramientas.

site_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/zsh/site-functions"
mkdir -p "${site_dir}"

# completado <orden> <argumentos del generador...>
completado() {
  local name="$1"
  shift
  if ! command -v "${name}" >/dev/null 2>&1; then
    echo "Omitido      ${name}: no está instalado"
    return 0
  fi
  if "${name}" "$@" >"${site_dir}/_${name}.tmp" 2>/dev/null; then
    mv "${site_dir}/_${name}.tmp" "${site_dir}/_${name}"
    echo "Generado     ${site_dir}/_${name}"
  else
    rm -f "${site_dir}/_${name}.tmp"
    echo "Advertencia: no se pudo generar el completado de ${name}." >&2
  fi
}

completado bw completion --shell zsh
completado ngrok completion zsh
completado mailpit completion zsh
