#!/usr/bin/env bash
set -euo pipefail

# Instala o actualiza opencode Desktop (la aplicación de escritorio de opencode)
# con el RPM oficial de opencode.ai, que la deja en /opt/OpenCode con su entrada
# en el menú de aplicaciones. No está en Fedora. El enlace "stable" redirige al
# RPM de la última versión: si es la instalada, no descarga nada. El RPM no viene
# firmado ni se publica su checksum. Lo ejecuta extras-install.sh; la
# configuración es la de opencode/.

stable_url="https://opencode.ai/download/stable/linux-x64-rpm"

# La URL a la que llega la redirección trae la versión: .../files/bin/<versión>/
rpm_url="$(curl --proto '=https' --tlsv1.2 -sSfIL -o /dev/null -w '%{url_effective}' "${stable_url}")"
if [[ ! "${rpm_url}" =~ /files/bin/([^/]+)/[^/]+\.rpm$ ]]; then
  echo "No se pudo obtener la última versión de opencode Desktop (${stable_url})." >&2
  exit 1
fi
latest="${BASH_REMATCH[1]}"
installed="$(rpm -q --qf '%{VERSION}' opencode 2>/dev/null || true)"

if [[ "${installed}" == "${latest}" ]]; then
  echo "opencode Desktop ${latest} ya está instalado."
  exit 0
fi

echo "Instalando opencode Desktop ${latest}..."
sudo dnf install -y "${rpm_url}"
