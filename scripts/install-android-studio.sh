#!/usr/bin/env bash
set -euo pipefail

# Instala Android Studio con el tarball oficial (versión y sha256 fijados aquí, de
# https://developer.android.com/studio) en ~/.local/share/android-studio, con su
# entrada en el menú de aplicaciones. Solo la primera vez: después se actualiza
# con su propio actualizador (Help → Check for Updates), que puede escribir ahí,
# así que la versión fija solo cuenta en una instalación nueva (check-versions.sh
# avisa cuando hay una más nueva). Trae su propio JDK (JetBrains Runtime) y usa el
# SDK de install-android-sdk.sh. Lo ejecuta extras-install.sh, después de
# install-android-sdk.sh.

studio_version="2026.2.2.9"
studio_file="android-studio-rabbit2-patch1-linux.tar.gz"
studio_sha256="11ecbf0e6dc0f04a1353f797e45bf239a3ff1a82221539b1b8cdd7eab0d8d8ea"
studio_url="https://dl.google.com/dl/android/studio/ide-zips/${studio_version}/${studio_file}"
data_dir="${XDG_DATA_HOME:-${HOME}/.local/share}"
studio_dir="${data_dir}/android-studio"
desktop_file="${data_dir}/applications/android-studio.desktop"

if [[ -x "${studio_dir}/bin/studio.sh" ]]; then
  echo "Android Studio ya está instalado (se actualiza solo)."
else
  echo "Instalando Android Studio ${studio_version} (unos 1,6 GB)..."
  # En el mismo sistema de archivos que el destino: extraído ocupa varios GB, que
  # no deben ir a /tmp (puede estar en RAM), y así basta un mv al final
  mkdir -p "${data_dir}"
  download_dir="$(mktemp -d "${data_dir}/android-studio.XXXXXX")"
  trap 'rm -rf "${download_dir}"' EXIT

  curl --proto '=https' --tlsv1.2 -sSfL -o "${download_dir}/studio.tar.gz" "${studio_url}"
  echo "${studio_sha256}  ${download_dir}/studio.tar.gz" | sha256sum -c --quiet
  tar -C "${download_dir}" -xzf "${download_dir}/studio.tar.gz"

  rm -rf "${studio_dir}"
  mv "${download_dir}/android-studio" "${studio_dir}"
  echo "Android Studio ${studio_version} instalado en ${studio_dir}."
fi

# StartupWMClass: la clase de ventana de Android Studio, para que GNOME agrupe la
# ventana con este ícono
mkdir -p "$(dirname "${desktop_file}")"
cat >"${desktop_file}" <<EOF
[Desktop Entry]
Type=Application
Name=Android Studio
Comment=Entorno de desarrollo para Android
Exec="${studio_dir}/bin/studio.sh" %f
Icon=${studio_dir}/bin/studio.svg
Categories=Development;IDE;
Terminal=false
StartupNotify=true
StartupWMClass=jetbrains-studio
EOF
