#!/usr/bin/env bash
set -euo pipefail

# Comprueba que cada paquete de packages.txt exista en los repositorios
# configurados (Fedora, RPM Fusion y los de etc/yum.repos.d) y que ninguno esté
# repetido: un nombre mal escrito haría fallar todo el dnf install de
# fedora-install.sh. No instala nada ni requiere sudo.
# Se ejecuta a mano, después de cambiar packages.txt.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export LC_ALL=C
status=0

mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' "${repo_root}/packages.txt" | sed 's/[[:space:]]*$//')

mapfile -t repeated < <(printf '%s\n' "${packages[@]}" | sort | uniq -d)
if ((${#repeated[@]} > 0)); then
  echo "Repetidos en packages.txt:" >&2
  printf '  %s\n' "${repeated[@]}" >&2
  status=1
fi

echo "Buscando ${#packages[@]} paquetes en los repositorios..."
mapfile -t missing < <(comm -23 <(printf '%s\n' "${packages[@]}" | sort -u) \
  <(dnf repoquery --quiet --queryformat '%{name}\n' "${packages[@]}" 2>/dev/null | sort -u))
if ((${#missing[@]} > 0)); then
  echo "No están en ningún repositorio configurado:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  status=1
fi

if ((status == 0)); then
  echo "Todos los paquetes de packages.txt existen."
fi
exit "${status}"
