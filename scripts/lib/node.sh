# shellcheck shell=bash
# Versión mayor de Node.js que se instala con fnm y queda como predeterminada. La
# usan install-runtimes.sh (primera instalación) y dotfiles-update.sh (actualiza
# a la última de esta versión mayor). No se usa fnm list-remote --latest: elige
# también las versiones de prueba (v27.0.0-alpha). Para pasar a otra versión
# mayor, se cambia solo node_major.
# Se carga con source.

node_major="26"

# node_latest <fnm>: la última versión publicada de node_major (vX.Y.Z), sin las
# de prueba (alpha, beta, rc). Devuelve 1 si no encuentra ninguna.
node_latest() {
  "$1" list-remote | awk -v major="${node_major}" '
    $1 ~ "^v" major "\\.[0-9]+\\.[0-9]+$" { latest = $1 }
    END { if (latest == "") exit 1; print latest }'
}
