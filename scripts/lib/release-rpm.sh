# shellcheck shell=bash
# Instala un RPM de los releases de GitHub del upstream, en una versión fija y con
# su sha256 (el que publica GitHub junto a cada archivo). La usan install-bruno.sh
# e install-dbeaver.sh. dnf instala el archivo local sin firma (los RPM de estos
# releases no están firmados): la garantía es el sha256 fijado en el script.
# Se carga con source.

# install_release_rpm <paquete> <versión> <url> <sha256>: si ya está instalada
# esa versión del paquete, no hace nada; si no, descarga el RPM, comprueba el
# sha256 y lo instala (o actualiza) con dnf.
install_release_rpm() {
  local package="$1" version="$2" url="$3" sha256="$4" installed download_dir
  installed="$(rpm -q --qf '%{VERSION}' "${package}" 2>/dev/null || true)"
  if [[ "${installed}" == "${version}" ]]; then
    echo "${package} ${version} ya está instalado."
    return
  fi

  echo "Instalando ${package} ${version}..."
  download_dir="$(mktemp -d)"
  # shellcheck disable=SC2064 # la ruta se fija ahora, no al salir
  trap "rm -rf '${download_dir}'" RETURN

  curl --proto '=https' --tlsv1.2 -sSfL -o "${download_dir}/${package}.rpm" "${url}"
  echo "${sha256}  ${download_dir}/${package}.rpm" | sha256sum -c --quiet
  sudo dnf install -y "${download_dir}/${package}.rpm"
  echo "${package} ${version} instalado."
}
