#!/usr/bin/env bash
set -euo pipefail

echo "Actualizando pgFormatter..."
exec "$(dirname "$0")/install-pgformatter.sh"
