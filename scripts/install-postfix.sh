#!/usr/bin/env bash
set -euo pipefail

# Deja Postfix solo local (paquete de packages.txt): escucha en loopback y no
# entrega fuera del equipo. El correo a otros dominios rebota y el aviso llega al
# buzón local (/var/spool/mail/$USER). Habilita el servicio y lo reinicia si
# cambió la configuración.
# Lo ejecuta fedora-install.sh; puede ejecutarse varias veces (sin sudo).

if ! rpm -q postfix >/dev/null 2>&1; then
  echo "No está instalado postfix (packages.txt)." >&2
  exit 1
fi

echo "Configurando Postfix (solo entrega local)..."
postfix_local=(
  "inet_interfaces = loopback-only"
  "default_transport = error:solo entrega local"
  "relay_transport = error:solo entrega local"
)
postfix_changed=false
for setting in "${postfix_local[@]}"; do
  if [[ "$(postconf -h "${setting%% = *}")" != "${setting#* = }" ]]; then
    sudo postconf -e "${setting}"
    postfix_changed=true
  fi
done
sudo systemctl enable --now postfix
# inet_interfaces se aplica al reiniciar, no con reload
if [[ "${postfix_changed}" == true ]]; then
  sudo systemctl restart postfix
fi
