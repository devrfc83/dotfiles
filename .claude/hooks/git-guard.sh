#!/usr/bin/env bash
set -euo pipefail

# Hook PreToolUse de Claude Code para este repositorio (lo declara
# .claude/settings.json): bloquea las órdenes de Bash que harían un commit o un
# push fuera del flujo de la skill dotfiles-workflow. El repositorio no guarda
# historial: los cambios se funden en el único commit con git rfc y se suben con
# git psr origin seadragon. Se permiten git rfc, git psr y git push con un lease
# explícito (--force-with-lease=<rama>:<commit>); se bloquean git commit, git
# push sin ese lease y sus alias (ci, cia, cie, cian, ps, psf, psu).
# Recibe en la entrada estándar el JSON de la herramienta; sale con 2 y un
# mensaje en stderr para bloquear (Claude lo lee), o con 0 para dejar pasar.

command="$(jq -r '.tool_input.command // empty')"

# git, con opciones globales opcionales (-C ruta, -c clave=valor), y el subcomando
git_re='(^|[;&|(`[:space:]])git([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+)*[[:space:]]+'
# Fin del subcomando: espacio, separador de órdenes o fin de línea
end_re='([[:space:];&|)]|$)'
commit_re="${git_re}(commit|ci|cia|cie|cian)${end_re}"
push_re="${git_re}(push|ps|psf|psu)${end_re}"
lease_re='--force-with-lease=[^[:space:]]+:[0-9a-f]{7,}'

block() {
  echo "Bloqueado por .claude/hooks/git-guard.sh: $1" >&2
  echo "Carga la skill dotfiles-workflow antes de un commit o un push: este repositorio" \
    "no guarda historial (git rfc para fundir los cambios, git psr origin seadragon para subirlos)." >&2
  exit 2
}

if [[ "${command}" =~ ${commit_re} ]]; then
  block "commit nuevo o enmienda sin git rfc."
fi

if [[ "${command}" =~ ${push_re} ]] && ! [[ "${command}" =~ ${lease_re} ]]; then
  block "push sin un lease explícito."
fi

exit 0
