#!/usr/bin/env bash
set -euo pipefail

# Instala en VSCodium y Cursor las extensiones de codium/extensions.txt que
# falten. Omite los editores que no estén instalados. Si una extensión falla,
# sigue con las demás y lo informa al final. Lo ejecuta extras-install.sh.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
extensions_file="${repo_root}/codium/extensions.txt"
failed=()

for editor in codium cursor; do
  if ! command -v "${editor}" >/dev/null 2>&1; then
    echo "Omitido      ${editor}: no está instalado"
    continue
  fi

  echo "Extensiones de ${editor}..."
  installed="$("${editor}" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"

  while read -r extension only; do
    [[ -z "${extension}" || "${extension}" == \#* ]] && continue
    [[ -n "${only}" && "${only}" != "${editor}" ]] && continue

    if grep -qxF "${extension,,}" <<<"${installed}"; then
      echo "Instalada    ${extension}"
    elif "${editor}" --install-extension "${extension}" >/dev/null 2>&1; then
      echo "Agregada     ${extension}"
    else
      echo "Error        ${extension}" >&2
      failed+=("${editor}: ${extension}")
    fi
  done <"${extensions_file}"
done

if ((${#failed[@]} > 0)); then
  printf 'No se pudieron instalar:\n' >&2
  printf '  %s\n' "${failed[@]}" >&2
  exit 1
fi
echo "Extensiones listas."
