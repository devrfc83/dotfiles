#!/usr/bin/env bash
set -euo pipefail

# Configura Docker CE (paquetes de packages.txt, repositorio en etc/yum.repos.d):
# - /etc/docker/daemon.json combinado con etc/docker/daemon.json, para publicar
#   los puertos en 127.0.0.1 (si cambia, respalda el anterior y reinicia Docker);
# - el servicio habilitado y el usuario en el grupo docker.
# Lo ejecuta fedora-install.sh; puede ejecutarse varias veces (sin sudo).

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
user="${USER:-$(id -un)}"

# shellcheck source=scripts/lib/backups.sh
source "${repo_root}/scripts/lib/backups.sh"

# El usuario que se agrega al grupo docker es el que ejecuta el script
if ((EUID == 0)); then
  echo "Este script debe ejecutarse como usuario normal, sin sudo." >&2
  exit 1
fi

if ! rpm -q docker-ce >/dev/null 2>&1; then
  echo "No está instalado docker-ce (packages.txt)." >&2
  exit 1
fi

echo "Configurando Docker..."
# Puertos publicados solo en 127.0.0.1 (etc/docker/daemon.json): por defecto,
# Docker los abre en todas las interfaces y con reglas propias, que firewalld no
# filtra. "ip" vale para la red bridge; default-network-opts, para las redes que
# crea cada proyecto (Compose). Para publicar en la red, debe indicarse la
# dirección: -p 0.0.0.0:8080:80. Se combina con el daemon.json que ya exista.
docker_config="/etc/docker/daemon.json"
docker_current="{}"
if sudo test -f "${docker_config}"; then
  docker_current="$(sudo cat "${docker_config}")"
fi
docker_merged="$(jq -s '.[0] * .[1]' <(printf '%s' "${docker_current}") "${repo_root}/etc/docker/daemon.json")"
if [[ "$(jq -S . <<<"${docker_current}")" != "$(jq -S . <<<"${docker_merged}")" ]]; then
  if sudo test -f "${docker_config}"; then
    sudo cp -p "${docker_config}" "${docker_config}${backup_suffix}"
    echo "Respaldo  ${docker_config} -> ${docker_config}${backup_suffix}"
    prune_backups "${docker_config}" sudo
  fi
  sudo install -d /etc/docker
  printf '%s\n' "${docker_merged}" | sudo tee "${docker_config}" >/dev/null
  echo "Generado  ${docker_config} (puertos publicados en 127.0.0.1)"
  # Solo si ya estaba en marcha: detiene los contenedores que no tengan restart
  sudo systemctl try-restart docker
fi
sudo systemctl enable --now docker

# Las redes de Compose creadas antes de este daemon.json conservan sus opciones y
# siguen publicando en todas las interfaces: deben recrearse.
mapfile -t old_networks < <(
  sudo docker network ls --filter driver=bridge --format '{{.Name}}' | while IFS= read -r network; do
    [[ "${network}" == bridge ]] && continue
    binding="$(sudo docker network inspect --format \
      '{{index .Options "com.docker.network.bridge.host_binding_ipv4"}}' "${network}")"
    [[ "${binding}" == 127.0.0.1 ]] || echo "${network}"
  done
)
if ((${#old_networks[@]} > 0)); then
  echo "Advertencia: estas redes publican los puertos en todas las interfaces: ${old_networks[*]}." >&2
  echo "  En cada proyecto: docker compose down && docker compose up -d" >&2
fi

if ! id -nG "${user}" | grep -qw docker; then
  sudo usermod -aG docker "${user}"
  echo "Se agregó ${user} al grupo docker; se aplica al volver a iniciar sesión."
fi
