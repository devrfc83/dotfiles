#!/usr/bin/env bash
set -euo pipefail

# Instala Go con el tarball oficial de go.dev en /usr/local/go (Fedora va una
# versión menor atrás), y luego gopls (servidor de lenguaje) y delve (depurador)
# con go install, en ~/go/bin. Si ya está la versión fijada, no descarga Go;
# gopls y delve se actualizan siempre a la última. El PATH lo agrega zsh/zshenv.
# Lo ejecuta extras-install.sh.
#
# Para cambiar de versión, deben actualizarse go_version y go_sha256 (el sha256
# del archivo linux-amd64 en https://go.dev/dl/?mode=json); check-versions.sh
# avisa cuando hay una nueva y muestra los dos valores.

go_version="1.27.3"
go_sha256="65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40"
go_url="https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"
go_root="/usr/local/go"
go_bin="${go_root}/bin/go"

if [[ "$(head -n 1 "${go_root}/VERSION" 2>/dev/null)" == "go${go_version}" ]]; then
  echo "Go ${go_version} ya está instalado."
else
  echo "Instalando Go ${go_version} (go.dev)..."
  download_dir="$(mktemp -d)"
  trap 'rm -rf "${download_dir}"' EXIT

  curl --proto '=https' --tlsv1.2 -sSfL -o "${download_dir}/go.tar.gz" "${go_url}"
  echo "${go_sha256}  ${download_dir}/go.tar.gz" | sha256sum -c --quiet

  # go.dev indica no extraer encima de una versión anterior: quedarían archivos viejos
  sudo rm -rf "${go_root}"
  sudo tar -C /usr/local -xzf "${download_dir}/go.tar.gz"
  echo "Go ${go_version} instalado en ${go_root}."
fi

echo "── gopls y delve ──"
"${go_bin}" install golang.org/x/tools/gopls@latest
"${go_bin}" install github.com/go-delve/delve/cmd/dlv@latest
