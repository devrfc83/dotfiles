#!/usr/bin/env bash
set -euo pipefail

# Clima para la barra de tmux (wttr.in) con caché.
# tmux ejecuta #(...) en cada status-interval (5 s, el valor de tmux-sensible;
# screen, cada 60 s con su backtick); el script solo consulta
# wttr.in cuando la caché tiene más de TMUX_WEATHER_TTL segundos, para no ser
# limitado por el servicio. Si la consulta falla, se muestra el último valor.
#
# Uso: tmux-weather [ubicación]   (por defecto: $CURRENT_LOCATION, de zsh/zshenv;
#                                  vacía, wttr.in la deduce de la IP)

location="${1:-${CURRENT_LOCATION:-}}"
ttl="${TMUX_WEATHER_TTL:-900}"
cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/tmux-weather"
cache_file="${cache_dir}/${location:-ip}"

mkdir -p "${cache_dir}"

if [[ -s "${cache_file}" ]]; then
  age=$(($(date +%s) - $(stat -c %Y "${cache_file}")))
  if ((age < ttl)); then
    cat "${cache_file}"
    exit 0
  fi
fi

tmp_file="$(mktemp "${cache_file}.XXXXXX")"
trap 'rm -f "${tmp_file}"' EXIT

if curl -sf --max-time 5 --user-agent curl "wttr.in/${location// /+}?format=3" >"${tmp_file}" &&
  [[ -s "${tmp_file}" ]]; then
  mv "${tmp_file}" "${cache_file}"
elif [[ -f "${cache_file}" ]]; then
  # Sin conexión: se conserva el valor anterior y se reintenta en el próximo TTL
  touch "${cache_file}"
fi

cat "${cache_file}" 2>/dev/null || true
