#!/usr/bin/env bash
set -euo pipefail

# Revisa los archivos del repositorio (los versionados y los nuevos aún sin git add):
# - scripts de bash (*.sh y el hook de pre-commit): ShellCheck y formato con shfmt,
#   que toma las reglas de .editorconfig (enlace a editorconfig/editorconfig);
# - archivos de zsh: sintaxis (zsh -n), que ShellCheck no admite;
# - tmux.conf: se carga en un servidor de tmux aparte, que informa opciones y
#   órdenes inválidas;
# - unidades de systemd: systemd-analyze verify;
# - gitconfig: que git pueda leerlos;
# - ajustes de VSCodium, Cursor, Zed y opencode: JSON con comentarios
#   (scripts/lib/check-jsonc.py);
#   etc/docker/daemon.json y las políticas de Chromium, JSON estricto;
# - colores: los archivos con colores propios (tmux, git, fzf, dircolors, pgcli)
#   solo usan los de la paleta Dracula (scripts/lib/check-palette.py);
# - Markdown: 80 columnas en la prosa (editorconfig); no cuentan las tablas, los
#   bloques de código ni los títulos; y que existan los archivos y los títulos de
#   los enlaces relativos (scripts/lib/check-md-links.py);
# - enlaces: que existan los orígenes del repositorio en scripts/lib/links.sh;
# - secretos: gitleaks en los archivos y en todo el historial de git (un secreto
#   borrado en un commit posterior sigue en el historial).
# Lo ejecuta el hook .githooks/pre-commit; también puede ejecutarse a mano. Para corregir el formato: shfmt -w <archivo>.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

for tool in git shellcheck shfmt zsh tmux systemd-analyze python3 gitleaks; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "No se encontró ${tool} (packages.txt)." >&2
    exit 1
  fi
done

# Archivos del repositorio que existen: los versionados (sin los borrados que aún no
# se registran) y los nuevos que no ignora .gitignore
repo_files() {
  local file
  git ls-files --cached --others --exclude-standard "$@" | sort -u | while IFS= read -r file; do
    if [[ -e "${file}" ]]; then
      echo "${file}"
    fi
  done
}

# fail <qué>: anota un error para el resumen final
errors=()
fail() {
  errors+=("$1")
}

# HOME temporal para tmux y systemd: los programas que ejecutan (TPM, los de las
# unidades) se reemplazan por archivos vacíos, para validar sin depender de
# dotfiles-install.sh ni ejecutar los reales
lint_home="$(mktemp -d)"
trap 'rm -rf "${lint_home}"' EXIT

# ── Bash y zsh ────────────────────────────────────────────────────────────────
mapfile -t files < <(repo_files '*.sh' .githooks)
mapfile -t zsh_files < <(repo_files 'zsh/*')

shellcheck -x "${files[@]}" || fail "ShellCheck"
shfmt -d "${files[@]}" || fail "formato (shfmt -w <archivo>)"
for file in "${zsh_files[@]}"; do
  zsh -n "${file}" || fail "sintaxis de zsh: ${file}"
done

# ── tmux ──────────────────────────────────────────────────────────────────────
install -D -m 755 /dev/null "${lint_home}/.tmux/plugins/tpm/tpm"
tmux_socket="lint-$$"
if ! tmux_output="$(HOME="${lint_home}" tmux -L "${tmux_socket}" -f /dev/null \
  new-session -d \; source-file tmux/tmux.conf 2>&1)"; then
  echo "tmux/tmux.conf: ${tmux_output}" >&2
  fail "tmux.conf"
fi
HOME="${lint_home}" tmux -L "${tmux_socket}" kill-server 2>/dev/null || true

# ── systemd ───────────────────────────────────────────────────────────────────
mapfile -t units < <(repo_files 'systemd/*.service' 'systemd/*.timer')
while IFS= read -r program; do
  install -D -m 755 /dev/null "${lint_home}/${program#%h/}"
done < <(grep -ohE '%h/[^[:space:]]+' "${units[@]}" | sort -u)
# --user necesita XDG_RUNTIME_DIR, que no existe sin sesión (contenedores)
install -d -m 700 "${lint_home}/run"
HOME="${lint_home}" XDG_RUNTIME_DIR="${lint_home}/run" systemd-analyze verify --user "${units[@]}" ||
  fail "unidades de systemd"

# ── gitconfig ─────────────────────────────────────────────────────────────────
while IFS= read -r file; do
  git config --file "${file}" --list >/dev/null || fail "gitconfig: ${file}"
done < <(repo_files 'git/gitconfig*')

# ── JSON con comentarios ──────────────────────────────────────────────────────
mapfile -t json_files < <(repo_files 'codium/*.json' 'opencode/*.json' 'zed/*.json')
python3 -I scripts/lib/check-jsonc.py "${json_files[@]}" || fail "JSON de los editores"
# JSON estricto: Docker (daemon.json) y las políticas de Chromium no admiten comentarios
mapfile -t strict_json_files < <(repo_files 'etc/docker/*.json' 'etc/chromium/*.json')
python3 -I -c 'import json, sys; [json.load(open(f, encoding="utf-8")) for f in sys.argv[1:]]' \
  "${strict_json_files[@]}" || fail "JSON de etc/docker y etc/chromium"

# ── Paleta ────────────────────────────────────────────────────────────────────
# Los archivos con colores propios solo usan los de scripts/lib/dracula.palette
palette_files=(tmux/tmux.conf screen/screenrc git/gitconfig zsh/zshenv input/dircolors pgcli/config)
python3 -I scripts/lib/check-palette.py scripts/lib/dracula.palette "${palette_files[@]}" ||
  fail "colores fuera de la paleta Dracula"

# ── Markdown ──────────────────────────────────────────────────────────────────
mapfile -t md_files < <(repo_files '*.md')
LC_ALL=C.UTF-8 awk '
  FNR == 1 { code = 0 }
  /^[[:space:]]*```/ { code = !code; next }
  code || /^[[:space:]]*[|#]/ { next }
  length($0) > 80 {
    printf "%s:%d: %d columnas (máximo 80)\n", FILENAME, FNR, length($0) > "/dev/stderr"
    bad = 1
  }
  END { exit bad }
' "${md_files[@]}" || fail "largo de línea en Markdown"
# Enlaces relativos entre documentos (archivo y #ancla)
python3 -I scripts/lib/check-md-links.py "${md_files[@]}" || fail "enlaces en Markdown"

# ── Enlaces ───────────────────────────────────────────────────────────────────
# dotfiles-install.sh solo avisa si falta un origen; aquí es un error. Los
# orígenes absolutos (/usr/bin/vimx) son de paquetes y no se revisan.
# shellcheck source=scripts/lib/links.sh
source scripts/lib/links.sh
for entry in "${links[@]}"; do
  source="${entry%%:*}"
  if [[ "${source}" != /* ]] && [[ ! -e "${source}" ]]; then
    echo "scripts/lib/links.sh: no existe ${source}" >&2
    fail "orígenes de links.sh"
  fi
done

# ── Secretos ──────────────────────────────────────────────────────────────────
# Los mismos archivos que el resto del lint (no los que ignora .gitignore), en una
# copia aparte, y todo el historial. Un falso positivo se acepta agregando su
# huella (Fingerprint) a .gitleaksignore.
secrets_dir="${lint_home}/secretos"
mkdir -p "${secrets_dir}"
mapfile -t all_files < <(repo_files)
cp --parents -t "${secrets_dir}" -- "${all_files[@]}"
gitleaks_opts=(--no-banner --redact --verbose --log-level warn)
gitleaks dir "${gitleaks_opts[@]}" --gitleaks-ignore-path . "${secrets_dir}" ||
  fail "secretos en los archivos (gitleaks)"
gitleaks git "${gitleaks_opts[@]}" . || fail "secretos en el historial de git (gitleaks)"

if ((${#errors[@]} > 0)); then
  printf 'Errores en: %s\n' "${errors[@]}" >&2
  exit 1
fi
echo "Lint sin errores."
