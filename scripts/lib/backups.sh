# shellcheck shell=bash
# Respaldos <archivo>.bak.<fecha> que dejan los scripts antes de reemplazar un
# archivo. Solo se guardan los más recientes de cada uno. Lo usan
# dotfiles-install.sh, dotfiles-uninstall.sh, install-minidlna.sh e install-docker.sh.
# Se carga con source.

# Respaldos que se guardan por archivo
backups_keep=3

# Sufijo de un respaldo nuevo: la fecha ordena los respaldos al ordenarlos como texto
# shellcheck disable=SC2034
backup_suffix=".bak.$(date +%Y%m%d%H%M%S)"

# backups_of <archivo>: sus respaldos, del más reciente al más antiguo
backups_of() {
  compgen -G "$1.bak.*" | sort -r || true
}

# prune_backups <archivo> [orden...]: borra los respaldos de <archivo> que pasen de
# backups_keep, empezando por los más antiguos. Con [orden] (por ejemplo, sudo), se
# borran a través de ella.
prune_backups() {
  local file="${1:?}"
  shift
  local -a backups
  local old
  mapfile -t backups < <(backups_of "${file}")
  for old in "${backups[@]:backups_keep}"; do
    "$@" rm -rf -- "${old}"
    echo "Borrado   ${old} (se guardan los ${backups_keep} respaldos más recientes)"
  done
}
