# shellcheck shell=bash
# Archivos de Nextcloud sincronizados con el cliente de escritorio (nextcloud-client):
# se leen como archivos locales, sin contraseñas ni la dirección del servidor en el
# repositorio. El cliente guarda en ~/.config/Nextcloud/nextcloud.cfg cada carpeta
# sincronizada (localPath) y la carpeta remota que refleja (targetPath). Se carga
# con source.

# nextcloud_path <ruta remota>
# Imprime la ruta local de <ruta remota> (por ejemplo, Respaldos/Fonts) dentro de
# alguna carpeta sincronizada, si ya está en el disco. Si no la encuentra así,
# prueba en ~/Nextcloud (la carpeta por defecto del cliente). Devuelve 1 si no
# está sincronizada (cliente sin configurar, carpeta excluida o aún sin bajar).
nextcloud_path() {
  local remote="/${1#/}"
  local config="${XDG_CONFIG_HOME:-${HOME}/.config}/Nextcloud/nextcloud.cfg"
  local key value folder local_path target candidate
  local -A local_paths=() targets=()

  if [[ -f "${config}" ]]; then
    while IFS='=' read -r key value; do
      # 0\Folders\1\localPath=/home/usuario/Nextcloud/ (o FoldersWithPlaceholders)
      [[ "${key}" =~ ^([0-9]+\\Folders[A-Za-z]*\\[0-9]+)\\(localPath|targetPath)$ ]] || continue
      folder="${BASH_REMATCH[1]}"
      value="${value#\"}"
      value="${value%\"}"
      if [[ "${BASH_REMATCH[2]}" == localPath ]]; then
        local_paths["${folder}"]="${value%/}"
      else
        targets["${folder}"]="/${value#/}"
      fi
    done <"${config}"
  fi

  for folder in "${!local_paths[@]}"; do
    local_path="${local_paths[${folder}]}"
    target="${targets[${folder}]:-/}"
    target="${target%/}"
    # La ruta remota debe estar dentro de la carpeta remota que se sincroniza
    [[ "${remote}" == "${target}" || "${remote}" == "${target}/"* ]] || continue
    candidate="${local_path}${remote#"${target}"}"
    if [[ -e "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  done

  candidate="${HOME}/Nextcloud${remote}"
  if [[ -e "${candidate}" ]]; then
    echo "${candidate}"
    return 0
  fi
  return 1
}
