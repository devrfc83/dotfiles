#!/usr/bin/env bash
set -euo pipefail

# Instala Piper (síntesis de voz neuronal, sin conexión) con pipx y descarga
# una voz en español. Lo usa zsh/scripts/buenos_dias.zsh; sin Piper, el saludo
# usa espeak-ng.
#
# Uso: install-piper.sh [voz]   (por defecto: es_MX-claude-high)
# Voces en español: es_MX-claude-high, es_MX-ald-medium, es_AR-daniela-high,
#                   es_ES-davefx-medium, es_ES-sharvard-medium
# Para actualizar Piper: pipx upgrade piper-tts

voice="${1:-es_MX-claude-high}"
voices_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/piper/voces"

if ! command -v pipx >/dev/null 2>&1; then
  echo "Este script requiere pipx (sudo dnf install -y pipx)." >&2
  exit 1
fi

echo "Instalando piper-tts con pipx..."
if pipx list --short 2>/dev/null | grep -q '^piper-tts '; then
  echo "piper-tts ya está instalado."
else
  pipx install piper-tts
fi

echo "Descargando la voz ${voice} en ${voices_dir}..."
mkdir -p "${voices_dir}"
venvs_dir="$(pipx environment --value PIPX_LOCAL_VENVS)"
"${venvs_dir}/piper-tts/bin/python" -m piper.download_voices \
  --download-dir "${voices_dir}" "${voice}"

echo "Piper instalado con la voz ${voice}."
echo "Para usar otra voz en el saludo: BUENOS_DIAS_VOZ=<voz> (en ~/.config/environment.d/ para el timer)."
