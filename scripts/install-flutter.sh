#!/usr/bin/env bash
set -euo pipefail

# Instala o actualiza Flutter (canal stable), que incluye Dart: no está en
# Fedora. La primera vez clona el repositorio oficial en ~/.local/share/flutter;
# después lo actualiza con flutter upgrade. Desactiva la telemetría de Flutter y
# de Dart. El PATH lo agrega zsh/zshenv; las dependencias para compilar apps de
# escritorio Linux están en packages.txt. Lo ejecuta extras-install.sh, antes de
# install-android-sdk.sh.

repo_url="https://github.com/flutter/flutter.git"
flutter_dir="${HOME}/.local/share/flutter"
flutter_bin="${flutter_dir}/bin/flutter"

if [[ -d "${flutter_dir}/.git" ]]; then
  "${flutter_bin}" upgrade
else
  git clone --depth 1 -b stable "${repo_url}" "${flutter_dir}"
  # La primera ejecución descarga el SDK de Dart y compila la herramienta
  "${flutter_bin}" --version
fi

"${flutter_bin}" --disable-analytics
"${flutter_dir}/bin/dart" --disable-analytics
