#!/usr/bin/env zsh
#
# buenos_dias.zsh — Saludo matutino con síntesis de voz
# Requiere: espeak-ng, curl
#

set -euo pipefail

# ── Fecha y hora ──────────────────────────────────────────────────────────────
DIA=$(LANG=es_ES.UTF-8 date +"%-d de %B de %Y")
HORA=$(LANG=es_ES.UTF-8 date +"%-H con %M")

# ── Temperatura (wttr.in) ─────────────────────────────────────────────────────
WTTR_OPTS=(-sf --user-agent "curl" --max-time 5)
TEMP_ACTUAL=$(curl "${WTTR_OPTS[@]}" 'wttr.in/Talca?format=%t' 2>/dev/null | tr -d '+' || echo "no disponible")
TEMP_MIN=$(curl    "${WTTR_OPTS[@]}" 'wttr.in/Talca?format=%m' 2>/dev/null | tr -d '+' || echo "no disponible")
TEMP_MAX=$(curl    "${WTTR_OPTS[@]}" 'wttr.in/Talca?format=%M' 2>/dev/null | tr -d '+' || echo "no disponible")

# ── Texto del saludo ──────────────────────────────────────────────────────────
MENSAJE="Buenos días Rodrigo. \
Hoy es ${DIA}. \
La hora actual es ${HORA}. \
La temperatura actual en Talca es ${TEMP_ACTUAL}. \
Para hoy, la temperatura mínima es ${TEMP_MIN} y la máxima es ${TEMP_MAX}."

# ── Síntesis de voz ───────────────────────────────────────────────────────────
espeak-ng -v es -s 145 -p 15 "${MENSAJE}"
