#!/usr/bin/env bash
set -euo pipefail

# Hooks globales de git (core.hooksPath = ~/.config/git/hooks, en git/gitconfig).
# Cada hook de este directorio es un enlace a este script (dispatch.sh), que:
# - en pre-commit, busca secretos en lo que se va a confirmar con gitleaks (si
#   está instalado); se salta con git commit --no-verify;
# - después ejecuta el hook propio del repositorio (.git/hooks/<hook>), que
#   core.hooksPath dejaría sin ejecutar; si no tiene, en los hooks de git-lfs
#   (pre-push, post-checkout, post-commit, post-merge) llama a git lfs, como
#   haría el hook que instala git lfs install.
# Un repositorio con su propio core.hooksPath (este, husky...) no pasa por aquí.

hook="$(basename "$0")"

if [[ "${hook}" == pre-commit ]] && command -v gitleaks >/dev/null 2>&1; then
  if ! gitleaks git --staged --no-banner --redact --verbose --log-level warn; then
    echo "gitleaks encontró secretos en el commit. Si es un falso positivo, debe agregarse" >&2
    echo "su huella (Fingerprint) a .gitleaksignore, o usarse git commit --no-verify." >&2
    exit 1
  fi
fi

# --git-common-dir y no --git-path: este último respeta core.hooksPath y apuntaría
# de nuevo a este script
repo_hook="$(git rev-parse --git-common-dir)/hooks/${hook}"
if [[ -x "${repo_hook}" ]]; then
  exec "${repo_hook}" "$@"
fi

case "${hook}" in
pre-push | post-checkout | post-commit | post-merge)
  if command -v git-lfs >/dev/null 2>&1; then
    exec git lfs "${hook}" "$@"
  fi
  ;;
esac
