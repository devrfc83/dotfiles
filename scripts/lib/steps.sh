# shellcheck shell=bash
# Pasos que siguen aunque uno falle, con un resumen al final (los usan
# extras-install.sh y dotfiles-update.sh). Se carga con source.

# Nombres de los pasos que fallaron
failed=()

# step <nombre> <orden> [argumentos...]
# Ejecuta la orden bajo un encabezado; si falla, lo informa y lo anota en failed.
step() {
  local name="$1"
  shift
  echo
  echo "── ${name} ──"
  if ! "$@"; then
    echo "Error en: ${name}" >&2
    failed+=("${name}")
  fi
}

# steps_report <mensaje>
# Informa los pasos que fallaron (y devuelve 1) o, si no hubo errores, el mensaje.
steps_report() {
  echo
  if ((${#failed[@]} > 0)); then
    echo "Terminado con errores en: ${failed[*]}" >&2
    return 1
  fi
  echo "$1"
}
