#!/usr/bin/env bash
set -euo pipefail

# Instala en VSCodium las extensiones de codium/extensions.txt que falten. Si
# VSCodium no está instalado, no hace nada. Si una extensión falla, sigue con las
# demás y lo informa al final. Lo ejecuta extras-install.sh.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
extensions_file="${repo_root}/codium/extensions.txt"
failed=()

if ! command -v codium >/dev/null 2>&1; then
  echo "Omitido: VSCodium no está instalado"
  exit 0
fi

echo "Extensiones de VSCodium..."
installed="$(codium --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"

while read -r extension; do
  [[ -z "${extension}" || "${extension}" == \#* ]] && continue

  if grep -qxF "${extension,,}" <<<"${installed}"; then
    echo "Instalada    ${extension}"
  elif codium --install-extension "${extension}" >/dev/null 2>&1; then
    echo "Agregada     ${extension}"
  else
    echo "Error        ${extension}" >&2
    failed+=("${extension}")
  fi
done <"${extensions_file}"

if ((${#failed[@]} > 0)); then
  printf 'No se pudieron instalar:\n' >&2
  printf '  %s\n' "${failed[@]}" >&2
  exit 1
fi
echo "Extensiones listas."
