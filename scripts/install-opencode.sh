#!/usr/bin/env bash
set -euo pipefail

# Instala o actualiza opencode (agente de programación en la terminal) con su
# instalador oficial, que deja el binario en ~/.opencode/bin. No está en Fedora.
# Con --no-modify-path no toca ~/.zshrc ni otros perfiles: el PATH lo agrega
# zsh/zshenv. Si ya está la última versión, el instalador no descarga nada. Lo
# ejecuta extras-install.sh; el tema y los permisos están en opencode/.

# El instalador compara con la versión de "opencode" en el PATH: sin esto, la
# volvería a descargar cada vez
PATH="${HOME}/.opencode/bin:${PATH}"

curl --proto '=https' --tlsv1.2 -sSfL https://opencode.ai/install |
  bash -s -- --no-modify-path
