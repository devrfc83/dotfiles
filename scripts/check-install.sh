#!/usr/bin/env bash
set -euo pipefail

# Prueba dotfiles-install.sh en un $HOME temporal y vacío: lo ejecuta dos veces y
# comprueba que la segunda no cambie nada (que puede ejecutarse varias veces) y
# que no deje enlaces rotos. Corre sin la sesión del usuario (sin D-Bus de sesión
# ni de sistema, sin XDG_RUNTIME_DIR y con GSettings en memoria), así que no toca
# GNOME, la foto de perfil, systemd --user ni el $HOME real: lo que necesita la
# sesión solo da avisos.
# Se ejecuta a mano (no la ejecuta el hook de pre-commit: tarda más que el lint).

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT
test_home="${work_dir}/home"
mkdir "${test_home}"

# run_install <n>: ejecuta dotfiles-install.sh en el $HOME de prueba y guarda su
# salida en salida-<n>. safe.directory va en el entorno (ámbito de línea de
# órdenes, que git respeta): en un contenedor el repositorio puede ser de otro
# usuario.
run_install() {
  if ! env -i HOME="${test_home}" USER="$(id -un)" PATH="/usr/local/bin:/usr/bin" LANG=C.UTF-8 \
    GSETTINGS_BACKEND=memory DBUS_SESSION_BUS_ADDRESS=disabled: DBUS_SYSTEM_BUS_ADDRESS=disabled: \
    GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0="${repo_root}" \
    bash "${repo_root}/scripts/dotfiles-install.sh" >"${work_dir}/salida-$1" 2>&1; then
    cat "${work_dir}/salida-$1" >&2
    echo "Falló dotfiles-install.sh (ejecución $1)." >&2
    exit 1
  fi
}

# snapshot: cada ruta del $HOME de prueba con su tipo, el destino de los enlaces y
# el SHA-256 de los archivos. Sin ~/.cache (la caché de fuentes cambia siempre).
snapshot() {
  (
    cd "${test_home}"
    find . -mindepth 1 -path ./.cache -prune -o -printf '%y %p %l\n' | sort
    find . -path ./.cache -prune -o -type f -print0 | sort -z | xargs -0 -r sha256sum
  )
}

run_install 1
snapshot >"${work_dir}/estado-1"
run_install 2
snapshot >"${work_dir}/estado-2"

errors=0
if ! diff -u "${work_dir}/estado-1" "${work_dir}/estado-2" >&2; then
  echo "La segunda ejecución cambió el \$HOME (arriba, las diferencias)." >&2
  errors=1
fi

mapfile -t broken < <(cd "${test_home}" && find . -path ./.cache -prune -o -xtype l -print)
if ((${#broken[@]} > 0)); then
  printf 'Enlace roto: ~/%s\n' "${broken[@]#./}" >&2
  errors=1
fi

if ((errors > 0)); then
  echo "Salida de la segunda ejecución:" >&2
  cat "${work_dir}/salida-2" >&2
  exit 1
fi
echo "dotfiles-install.sh sin errores: la segunda ejecución no cambió nada."
