#!/usr/bin/env zsh
#
# buenos_dias.zsh — Saludo matutino con síntesis de voz
# Requiere: curl, jq y piper (scripts/install-piper.sh) o espeak-ng
# Voz de Piper: variable BUENOS_DIAS_VOZ (por defecto: es_MX-claude-high)
#

set -euo pipefail

# ── Fecha y hora ──────────────────────────────────────────────────────────────
DIA=$(LANG=es_ES.UTF-8 date +"%-d de %B de %Y")
HORA=$(LANG=es_ES.UTF-8 date +"%-H con %M")

# ── Temperatura (wttr.in) ─────────────────────────────────────────────────────
# Una sola consulta en JSON (format=j1). En el formato de una línea, %m y %M
# son la fase y el día lunar, no la mínima y la máxima.
WTTR_OPTS=(-sf --user-agent "curl" --max-time 5)
WTTR_JSON=$(curl "${WTTR_OPTS[@]}" 'wttr.in/Talca?format=j1' 2>/dev/null || true)

temperatura() {
  local valor
  valor=$(jq -er "$1" <<< "${WTTR_JSON}" 2>/dev/null) || { echo "no disponible"; return; }
  echo "${valor} grados"
}

TEMP_ACTUAL=$(temperatura '.current_condition[0].temp_C')
TEMP_MIN=$(temperatura '.weather[0].mintempC')
TEMP_MAX=$(temperatura '.weather[0].maxtempC')

# ── Texto del saludo ──────────────────────────────────────────────────────────
MENSAJE="Buenos días Rodrigo. \
Hoy es ${DIA}. \
La hora actual es ${HORA}. \
La temperatura actual en Talca es ${TEMP_ACTUAL}. \
Para hoy, la temperatura mínima es ${TEMP_MIN} y la máxima es ${TEMP_MAX}."

# ── Síntesis de voz ───────────────────────────────────────────────────────────
# Piper (voz neuronal, natural) si está instalado; si no, espeak-ng.
VOZ="${BUENOS_DIAS_VOZ:-es_MX-claude-high}"
MODELO="${XDG_DATA_HOME:-$HOME/.local/share}/piper/voces/${VOZ}.onnx"

if (( $+commands[piper] )) && [[ -f "${MODELO}" ]] && (( $+commands[pw-play] )); then
  WAV=$(mktemp --suffix=.wav)
  trap 'rm -f "${WAV}"' EXIT
  print -r -- "${MENSAJE}" | piper -m "${MODELO}" -f "${WAV}" 2>/dev/null
  pw-play "${WAV}"
else
  espeak-ng -v es-419 -s 140 -p 40 "${MENSAJE}"
fi
