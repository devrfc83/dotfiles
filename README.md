# Dotfiles

Mis archivos de configuración y preferencias de usuario, para **Fedora Linux
44+** (Workstation): zsh con oh-my-zsh, tmux, Vim, VSCodium y Cursor, con la
paleta Dracula, y un entorno de desarrollo con PHP, Node.js, Rust, Vala y
PostgreSQL. Antes de usarlos, conviene leer la [advertencia](#advertencia).

## Inicio rápido

Como usuario normal, sin `sudo` (los scripts lo piden cuando hace falta):

```bash
git clone https://github.com/devrfc83/dotfiles.git ~/Code/Dotfiles
cd ~/Code/Dotfiles
bash scripts/fedora-install.sh
```

`fedora-install.sh` configura los repositorios (RPM Fusion, VSCodium, Cursor,
GitHub CLI y Docker CE), instala los paquetes de `packages.txt` y deja listos
PostgreSQL, Docker, Podman, libvirt y los servicios locales. Al final ejecuta
`dotfiles-install.sh` (enlaces en `$HOME` y ajustes de GNOME) y
`extras-install.sh` (rustup, fnm con Node.js, oh-my-zsh, plugins y programas
compilados). El detalle está en [Instalación](docs/instalacion.md).

Después:

1. Cerrar la sesión y volver a entrar: grupos `docker` y `libvirt`, zsh como
   shell y extensiones de GNOME.
2. Iniciar sesión en `gh` (`gh auth login`) y en `doctl` (`doctl auth init`).
3. Si no estaba, sincronizar la carpeta `Respaldos` de Nextcloud (fuentes y BIOS
   de PlayStation) y volver a ejecutar `bash scripts/dotfiles-install.sh`.

## Uso diario

| Tarea                            | Orden                                         |
| -------------------------------- | --------------------------------------------- |
| Actualizar todo                  | `bash scripts/dotfiles-update.sh`             |
| Revisar las versiones fijas      | `bash scripts/check-versions.sh`              |
| Volver a aplicar los enlaces     | `bash scripts/dotfiles-install.sh`            |
| Ver los enlaces sin cambiar nada | `bash scripts/dotfiles-install.sh --mostrar`  |
| Revisar el repositorio           | `bash scripts/lint.sh`                        |
| Comprobar `packages.txt`         | `bash scripts/check-packages.sh`              |
| Quitar los enlaces               | `bash scripts/dotfiles-uninstall.sh`          |

Más en [Mantenimiento](docs/mantenimiento.md).

## Documentación

El índice completo, con lo que uso y la historia del repositorio, está en
[docs/](docs/README.md): [Instalación](docs/instalacion.md) ·
[Terminal](docs/terminal.md) · [Editores](docs/editores.md) ·
[Desarrollo](docs/desarrollo.md) · [PostgreSQL](docs/postgresql.md) ·
[Servicios locales](docs/servicios.md) · [Escritorio](docs/escritorio.md) ·
[Seguridad](docs/seguridad.md) · [Extras](docs/extras.md) ·
[Mantenimiento](docs/mantenimiento.md).

## Licencia

En términos generales, se considera que el contenido de los dotfiles se rige por
los términos y condiciones de las licencias de software a las que pertenecen.

## Advertencia

Este repositorio es público como una forma de no perder el acceso a mis propios
archivos de configuración y preferencias de usuario, no con fines colaborativos,
ya que no tengo intención de mantener un historial ni garantizar la consistencia
de este repositorio a lo largo del tiempo.

- Deben leerse los archivos antes de usarlos.
- Pueden extraerse fragmentos para adaptarlos a dotfiles propios.
- No debe usarse este repositorio en otras computadoras.
- No debe hacerse fork de este repositorio a menos que se sepa cómo usarlo.

## Problemas / Pull Requests

Si se usa este repositorio o parte de él y se encuentra que algo no funciona
correctamente, puede abrirse un issue en este repositorio de GitHub. No es
necesario abrir un pull request.
