#!/usr/bin/env bash
set -euo pipefail

# Instala el Android SDK sin Android Studio, en ~/.local/share/android-sdk. La
# primera vez descarga las command-line tools de Google (versión y sha256 fijados
# aquí, de https://developer.android.com/studio, «Command line tools only») y,
# con ellas, instala el paquete cmdline-tools;latest: así queda registrado y se
# actualiza con el resto del SDK. Después instala con la Android CLI (android sdk,
# que reemplaza a sdkmanager) platform-tools (adb, fastboot), la plataforma con
# que compila Flutter y las build-tools más nuevas, y actualiza todo; Gradle
# descarga las demás versiones que pida cada proyecto. Sin emulador.
#
# La Android CLI envía métricas de uso si no se le pasa --no-metrics. Las
# licencias se aceptan a mano con sdkmanager (el que usa Flutter): si hay una
# terminal, sdkmanager --licenses pregunta por las que falten. Requiere el JDK de
# packages.txt. ANDROID_HOME y el PATH los agrega zsh/zshenv. Lo ejecuta
# extras-install.sh, después de install-flutter.sh.

cmdline_tools_version="15859902"
cmdline_tools_sha256="4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583"
cmdline_tools_url="https://dl.google.com/android/repository/commandlinetools-linux-${cmdline_tools_version}_latest.zip"
sdk_root="${HOME}/.local/share/android-sdk"
tools_dir="${sdk_root}/cmdline-tools/latest"
sdkmanager="${tools_dir}/bin/sdkmanager"
android=("${tools_dir}/bin/android" --no-metrics --sdk="${sdk_root}")
flutter_dir="${HOME}/.local/share/flutter"
flutter_bin="${flutter_dir}/bin/flutter"

# accept_licenses <sdkmanager> [opciones]: pregunta por las licencias que falten,
# solo si hay una terminal
accept_licenses() {
  if [[ -t 0 ]]; then
    "$@" --licenses
  else
    echo "Sin terminal: no se preguntan las licencias (sin ellas, no se instala nada)."
  fi
}

# package.xml lo escribe el gestor del SDK: sin él, cmdline-tools/latest es una
# copia del zip que no se actualiza
if [[ ! -f "${tools_dir}/package.xml" ]]; then
  echo "Instalando las command-line tools de Android (paquete cmdline-tools;latest)..."
  download_dir="$(mktemp -d)"
  trap 'rm -rf "${download_dir}"' EXIT

  curl --proto '=https' --tlsv1.2 -sSfL -o "${download_dir}/cmdline-tools.zip" "${cmdline_tools_url}"
  echo "${cmdline_tools_sha256}  ${download_dir}/cmdline-tools.zip" | sha256sum -c --quiet
  unzip -q "${download_dir}/cmdline-tools.zip" -d "${download_dir}"

  # Si cmdline-tools/latest ya existe, sdkmanager instalaría en latest-2
  rm -rf "${tools_dir}"
  bootstrap=("${download_dir}/cmdline-tools/bin/sdkmanager" --sdk_root="${sdk_root}")
  accept_licenses "${bootstrap[@]}"
  # Sin entrada: con una licencia sin aceptar, sdkmanager esperaría una respuesta
  "${bootstrap[@]}" --install "cmdline-tools;latest" </dev/null
  if [[ ! -f "${tools_dir}/package.xml" ]]; then
    echo "No se instalaron las command-line tools: deben aceptarse las licencias (ejecutar en una terminal)." >&2
    exit 1
  fi
else
  accept_licenses "${sdkmanager}"
fi

# newest <patrón>: el paquete más nuevo del repositorio cuyo nombre calza con el
# patrón (sin -rc ni versiones previas)
newest() {
  grep -oE "^ +$1 " <<<"${available}" | tr -d ' ' | sort -V | tail -n 1
}

# La plataforma: la API con que compilan por defecto los proyectos de Flutter
# (compileSdkVersion); sin Flutter, la más nueva sin versión menor (android-NN).
# Las build-tools: las más nuevas estables
available="$("${android[@]}" sdk list --all 2>/dev/null)"
flutter_api="$(sed -n 's/.*val compileSdkVersion: Int = \([0-9]*\).*/\1/p' \
  "${flutter_dir}/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt" 2>/dev/null || true)"
if [[ -n "${flutter_api}" ]]; then
  platform="platforms/android-${flutter_api}"
else
  platform="$(newest 'platforms/android-[0-9]+')"
fi
build_tools="$(newest 'build-tools/[0-9.]+')"
if [[ -z "${platform}" || -z "${build_tools}" ]]; then
  echo "No se pudo leer la lista de paquetes del SDK." >&2
  exit 1
fi

echo "── platform-tools, ${platform} y ${build_tools} ──"
"${android[@]}" sdk install platform-tools "${platform}" "${build_tools}" </dev/null
"${android[@]}" sdk update </dev/null
# android sdk install no falla si no encuentra un paquete o le falta la licencia
for dir in platform-tools "${platform}" "${build_tools}"; do
  if [[ ! -f "${sdk_root}/${dir}/package.xml" ]]; then
    echo "No se instaló ${dir}: deben aceptarse las licencias (flutter doctor --android-licenses)." >&2
    exit 1
  fi
done

if [[ -x "${flutter_bin}" ]]; then
  "${flutter_bin}" config --android-sdk "${sdk_root}"
fi
