# shellcheck shell=bash
# Funciones compartidas por los scripts de instalación (se cargan con source).

# sync_repo <directorio> <url>
# Clona el repositorio si no existe o lo actualiza con git pull --ff-only.
# Si el directorio existe pero no es un repositorio, o su origen es otro, no lo
# toca y devuelve 1.
sync_repo() {
  local dir="$1"
  local url="$2"
  local name before

  name="$(basename "${dir}")"

  if [[ -d "${dir}/.git" ]]; then
    if [[ "$(git -C "${dir}" remote get-url origin)" != "${url}" ]]; then
      echo "Omitido      ${name}: el origen no es ${url}" >&2
      return 1
    fi
    before="$(git -C "${dir}" rev-parse HEAD)"
    git -C "${dir}" pull --ff-only --quiet
    if [[ "$(git -C "${dir}" rev-parse HEAD)" == "${before}" ]]; then
      echo "Al día       ${name}"
    else
      echo "Actualizado  ${name}"
    fi
  elif [[ -e "${dir}" ]]; then
    echo "Omitido      ${name}: ${dir} existe pero no es un repositorio git" >&2
    return 1
  else
    mkdir -p "$(dirname "${dir}")"
    git clone --depth 1 --quiet "${url}" "${dir}"
    echo "Clonado      ${name}"
  fi
}
