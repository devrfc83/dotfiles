#!/usr/bin/env bash
set -euo pipefail

# Compara los programas que se compilan o descargan en una versión o commit fijo
# con su upstream, y avisa cuáles tienen algo más nuevo (con el valor que debe
# ponerse en su script). No cambia nada: actualizar es editar el script y volver a
# ejecutarlo.
# Lo ejecuta dotfiles-update.sh al final; también puede ejecutarse a mano.
#
# Las versiones se leen de los install-*.sh (líneas variable="valor"), así que
# quedan en un solo lugar. Requiere git, curl y jq.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
outdated=0

# pinned <script> <variable>: el valor de <variable>="..." en scripts/<script>
pinned() {
  sed -n "s/^$2=\"\([^\"]*\)\".*/\1/p" "${scripts_dir}/$1" | head -n 1
}

# report <nombre> <fijo> <upstream> <qué cambiar>
report() {
  if [[ -z "$3" ]]; then
    echo "Sin datos  $1 $2 (no se pudo consultar el upstream)" >&2
  elif [[ "$2" == "$3" ]]; then
    echo "Al día     $1 $2"
  else
    echo "Nueva      $1 $2 -> $3 ($4)"
    outdated=$((outdated + 1))
  fi
}

# Último commit de la rama principal de un repositorio git
remote_head() {
  git ls-remote "$1" HEAD 2>/dev/null | cut -f 1
}

# check_tag <nombre> <script> <prefijo>: versión fija en un tag (<prefijo><versión>)
# frente al tag más nuevo, con el commit de ese tag
check_tag() {
  local name="$1" script="$2" prefix="$3" url latest hint tag_commit
  url="$(pinned "${script}" repo_url)"
  # Solo tags de versión (números, puntos y guiones): no los de archivo ni otros
  latest="$(git ls-remote --tags --refs "${url}" 2>/dev/null | sed -n "s|.*refs/tags/${prefix}||p" |
    grep -E '^[0-9][0-9.-]*$' | sort -V | tail -n 1)"
  hint="${script}: version=\"${latest}\""
  if [[ -n "${latest}" ]]; then
    # En un tag anotado, la referencia ^{} es el commit (la otra, el objeto del tag);
    # sort -r la deja primero
    tag_commit="$(git ls-remote "${url}" "refs/tags/${prefix}${latest}^{}" "refs/tags/${prefix}${latest}" 2>/dev/null |
      sort -r -k 2 | head -n 1 | cut -f 1)"
    hint+=" y commit=\"${tag_commit}\""
  fi
  report "${name}" "$(pinned "${script}" version)" "${latest}" "${hint}"
}

check_tag pgFormatter install-pgformatter.sh v
check_tag "Tela (iconos)" install-tela-icons.sh ""
check_tag nikto install-nikto.sh ""

# Compilados en un commit fijo: se comparan con el último de la rama principal
for entry in "tty-clock:install-tty-clock.sh" "Genesis Plus GX:install-genesis-plus-gx.sh"; do
  name="${entry%%:*}"
  script="${entry#*:}"
  commit="$(pinned "${script}" commit)"
  head="$(remote_head "$(pinned "${script}" repo_url)")"
  report "${name}" "${commit:0:7}" "${head:0:7}" "${script}: commit=\"${head}\""
done

# tint: la versión más nueva en Debian (sources.debian.org)
script="install-tint.sh"
latest="$(curl -sf --max-time 15 https://sources.debian.org/api/src/tint/ 2>/dev/null |
  jq -r '.versions[].version' 2>/dev/null | sort -V | tail -n 1 || true)"
report tint "$(pinned "${script}" tint_version)" "${latest}" \
  "${script}: tint_version=\"${latest}\" y tint_sha256 (Checksums-Sha256 del .dsc)"

# Go: la versión estable más nueva en go.dev, con el sha256 de su tarball linux-amd64
script="install-go.sh"
go_release="$(curl -sf --max-time 15 'https://go.dev/dl/?mode=json' 2>/dev/null |
  jq -r '.[0] | .version + " " + (.files[] | select(.os == "linux" and .arch == "amd64" and .kind == "archive") | .sha256)' \
    2>/dev/null || true)"
latest="${go_release%% *}"
latest="${latest#go}"
report Go "$(pinned "${script}" go_version)" "${latest}" \
  "${script}: go_version=\"${latest}\" y go_sha256=\"${go_release#* }\""

echo
if ((outdated > 0)); then
  echo "Hay ${outdated} con versión nueva: debe cambiarse el script indicado y ejecutarse de nuevo."
else
  echo "Todas las versiones fijas están al día."
fi
