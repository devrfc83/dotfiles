#!/usr/bin/env bash
set -euo pipefail

# Instala las skills globales de Claude Code que vienen de terceros, en
# ~/.claude/skills (directorio real: las propias, de skills/, se enlazan archivo
# por archivo desde scripts/lib/links.sh, y las que sincroniza Claude quedan en
# ~/.claude/skills/synced). Nada de esto entra al repositorio.
#
# - skills_cli: con el CLI skills (npx skills add -g -a claude-code -y), que
#   copia cada skill en ~/.claude/skills y anota su origen y commit en
#   ~/.agents/.skill-lock.json (lo usa npx skills update). Cada entrada es
#   "<origen> [skill...]"; sin skills, instala todas las del origen.
# - templates_skills: con claude-code-templates, que instala en
#   <directorio>/.claude/skills (por eso --directory "$HOME").
#
# Ambos se ejecutan con npx en su última versión, sin versión ni checksum fijos
# (como los instaladores oficiales de Zed y opencode), y con la telemetría
# apagada (DO_NOT_TRACK, CCT_NO_TRACKING). Se ejecuta desde $HOME para que
# ninguno instale en el .claude/ del directorio actual.
# Lo ejecuta extras-install.sh; dotfiles-update.sh además las actualiza con
# npx skills update -g. Puede ejecutarse varias veces: reinstala en la última
# versión. Requiere Node 22.20 o posterior (fnm, scripts/lib/node.sh).
# Para quitar una: npx skills remove -g <skill>.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

skills_cli=(
  # frontend-design (antes en anthropics/claude-code) y las document-skills (los
  # documentos de Office y PDF de Anthropic)
  "anthropics/skills frontend-design docx pdf pptx xlsx"
  "https://github.com/browser-use/browser-use browser-use"
  "unicodeveloper/shannon"
  "https://github.com/coleam00/excalidraw-diagram-skill excalidraw-diagram"
  # Respuestas más cortas (JuliusBrussee/caveman, no shawnchee/caveman-skill)
  "JuliusBrussee/caveman"
  "addyosmani/agent-skills"
)
templates_skills=(development/code-reviewer)

export DO_NOT_TRACK=1 CCT_NO_TRACKING=true

# fnm solo se activa en zsh; aquí se activa a mano (Node por defecto) para encontrar npx
if ! command -v npx >/dev/null 2>&1 && command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --shell bash)"
fi
if ! command -v npx >/dev/null 2>&1; then
  echo "Este script requiere npx (Node con fnm: scripts/install-runtimes.sh)." >&2
  exit 1
fi

# shellcheck source=scripts/lib/steps.sh
source "${scripts_dir}/lib/steps.sh"

cd "${HOME}"

for entry in "${skills_cli[@]}"; do
  read -ra words <<<"${entry}"
  args=(add "${words[0]}" -g -a claude-code -y)
  if ((${#words[@]} > 1)); then
    args+=(--skill "${words[@]:1}")
  fi
  step "skills: ${entry}" npx --yes skills@latest "${args[@]}"
done

for skill in "${templates_skills[@]}"; do
  step "claude-code-templates: ${skill}" \
    npx --yes claude-code-templates@latest --skill "${skill}" --directory "${HOME}" --yes
done

steps_report "Skills de Claude Code instaladas."
