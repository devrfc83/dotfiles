#!/usr/bin/env zsh
#
# buenos_dias.zsh — Saludo matutino con síntesis de voz
# Requiere: curl y jq. La voz, en este orden según lo que haya: edge-tts (pipx;
# voces neuronales de Microsoft, requiere conexión) con mpv, Piper
# (scripts/install-piper.sh; neuronal, sin conexión) con pw-play, o espeak-ng.
# Voz de edge-tts: variable BUENOS_DIAS_VOZ_EDGE (por defecto: es-MX-JorgeNeural)
# Voz de Piper: variable BUENOS_DIAS_VOZ (por defecto: es_MX-claude-high)
#
# Uso: buenos-dias [--texto] [--voz edge|piper|espeak]
#   --texto  solo imprime el saludo, sin hablar
#   --voz    usa solo esa voz (para probarla), sin pasar a la siguiente si falla
#

set -euo pipefail

solo_texto=false
voz_forzada=""
while (($# > 0)); do
  case "$1" in
    --texto) solo_texto=true ;;
    --voz)
      voz_forzada="${2:-}"
      [[ "${voz_forzada}" == (edge|piper|espeak) ]] || { echo "Uso: buenos-dias [--texto] [--voz edge|piper|espeak]" >&2; exit 1; }
      shift
      ;;
    *) echo "Uso: buenos-dias [--texto] [--voz edge|piper|espeak]" >&2; exit 1 ;;
  esac
  shift
done

# ── Fecha y hora ──────────────────────────────────────────────────────────────
DIA=$(LANG=es_ES.UTF-8 date +"%-d de %B de %Y")
HORA=$(LANG=es_ES.UTF-8 date +"%-H con %M")

# ── Temperatura (wttr.in) ─────────────────────────────────────────────────────
# Ubicación: CURRENT_LOCATION, de ~/.zshenv (zsh lo carga también en scripts)
UBICACION="${CURRENT_LOCATION:-}"
# Una sola consulta en JSON (format=j1). En el formato de una línea, %m y %M
# son la fase y el día lunar, no la mínima y la máxima.
WTTR_OPTS=(-sf --user-agent "curl" --max-time 5)
WTTR_JSON=$(curl "${WTTR_OPTS[@]}" "wttr.in/${UBICACION// /+}?format=j1" 2>/dev/null || true)

# temperatura <filtro jq>: el valor en grados; falla si la respuesta no lo trae
temperatura() {
  jq -er "$1" <<< "${WTTR_JSON}" 2>/dev/null
}

# Si falta cualquiera de los tres valores (sin red, servicio caído o respuesta
# incompleta), se dice claramente en vez de leer «no disponible» como un número
if TEMP_ACTUAL=$(temperatura '.current_condition[0].temp_C') &&
   TEMP_MIN=$(temperatura '.weather[0].mintempC') &&
   TEMP_MAX=$(temperatura '.weather[0].maxtempC'); then
  CLIMA="La temperatura actual${UBICACION:+ en ${UBICACION}} es de ${TEMP_ACTUAL} grados. \
Para hoy, la mínima será de ${TEMP_MIN} grados y la máxima, de ${TEMP_MAX}."
else
  CLIMA="El servicio de temperatura no está disponible en este momento."
fi

# ── Texto del saludo ──────────────────────────────────────────────────────────
MENSAJE="Buenos días Rodrigo. \
Hoy es ${DIA}. \
La hora actual es ${HORA}. \
${CLIMA}"

if [[ "${solo_texto}" == true ]]; then
  print -r -- "${MENSAJE}"
  exit 0
fi

# ── Síntesis de voz ───────────────────────────────────────────────────────────
VOZ_EDGE="${BUENOS_DIAS_VOZ_EDGE:-es-MX-JorgeNeural}"
VOZ_PIPER="${BUENOS_DIAS_VOZ:-es_MX-claude-high}"
MODELO="${XDG_DATA_HOME:-$HOME/.local/share}/piper/voces/${VOZ_PIPER}.onnx"
AUDIO_DIR=$(mktemp -d)
trap 'rm -rf "${AUDIO_DIR}"' EXIT

# edge-tts genera un MP3 (siempre, sea cual sea la extensión): lo reproduce mpv.
# Un poco más lento y grave que la voz por defecto. Sin conexión falla y se pasa
# a la siguiente voz; timeout evita que se quede esperando al servicio.
hablar_edge() {
  (( $+commands[edge-tts] )) && (( $+commands[mpv] )) || return 1
  timeout 60 edge-tts --voice "${VOZ_EDGE}" --rate="-2%" --pitch="-10Hz" \
    --write-media "${AUDIO_DIR}/saludo.mp3" --text "${MENSAJE}" 2>/dev/null || return 1
  [[ -s "${AUDIO_DIR}/saludo.mp3" ]] || return 1
  echo "Voz: edge-tts (${VOZ_EDGE})"
  mpv --no-video --really-quiet "${AUDIO_DIR}/saludo.mp3"
}

# Piper (sin conexión) con la voz descargada por install-piper.sh
hablar_piper() {
  (( $+commands[piper] )) && [[ -f "${MODELO}" ]] && (( $+commands[pw-play] )) || return 1
  print -r -- "${MENSAJE}" | piper -m "${MODELO}" -f "${AUDIO_DIR}/saludo.wav" 2>/dev/null || return 1
  echo "Voz: Piper (${VOZ_PIPER})"
  pw-play "${AUDIO_DIR}/saludo.wav"
}

hablar_espeak() {
  echo "Voz: espeak-ng"
  espeak-ng -v es-419 -s 140 -p 40 "${MENSAJE}"
}

case "${voz_forzada}" in
  edge) hablar_edge || { echo "edge-tts no está disponible (¿edge-tts, mpv, conexión?)." >&2; exit 1; } ;;
  piper) hablar_piper || { echo "Piper no está disponible (¿piper, la voz ${VOZ_PIPER}, pw-play?)." >&2; exit 1; } ;;
  espeak) hablar_espeak ;;
  *) hablar_edge || hablar_piper || hablar_espeak ;;
esac
