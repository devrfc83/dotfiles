# Mantenimiento

Actualizar, revisar las versiones fijas, lint y desinstalar.

[← Volver al índice](README.md)

## Actualizar

`scripts/dotfiles-update.sh` actualiza todo en un solo comando, sin `sudo` (lo
pide cuando hace falta): los paquetes DNF, también los que se agregaron a
`packages.txt` desde la última vez; el firmware (`fwupdmgr`, que pide
confirmación por cada dispositivo); los enlaces nuevos de
`scripts/lib/links.sh` (`dotfiles-install.sh --enlaces`, que no vuelve a
cargar los ajustes de GNOME); lo de `extras-install.sh`, también Flutter, el
Android SDK, opencode y opencode Desktop (Zed se actualiza solo); Node.js (la
última
versión con fnm, que queda como predeterminada); pipx y las extensiones de
VSCodium y Cursor. Si un paso falla, sigue con los demás y lo informa al final.

Al terminar ejecuta `scripts/check-versions.sh`, que compara con su upstream los
programas compilados o descargados en una versión o commit fijo (pgFormatter,
tty-clock, Genesis Plus GX, tint, el tema de iconos Tela, nikto y Go) y, si hay
algo más
nuevo, indica el valor que debe ponerse en su script. No cambia nada: para
actualizar uno, se edita su script y se ejecuta de nuevo.

```bash
bash scripts/dotfiles-update.sh   # todo
bash scripts/check-versions.sh    # solo revisar las versiones fijas
```

## Hook de pre-commit y revisiones

Antes de cada commit, `.githooks/pre-commit` ejecuta `scripts/lint.sh`, que
revisa:

- los scripts de bash (`*.sh` y el propio hook) con **ShellCheck**, y su formato
  con **shfmt**, que toma las reglas de `.editorconfig` (en la raíz, un enlace a
  `editorconfig/editorconfig`);
- la sintaxis de los archivos de `zsh/` con `zsh -n` (ShellCheck no admite zsh);
- `tmux/tmux.conf`, cargándolo en un servidor de tmux aparte;
- las unidades de `systemd/` con `systemd-analyze verify`;
- que git pueda leer los `gitconfig`;
- los ajustes de VSCodium y Cursor (JSON con comentarios);
- el largo de línea del Markdown: 80 columnas en la prosa, sin contar tablas,
  bloques de código ni títulos;
- que existan los orígenes de `scripts/lib/links.sh` que están en el
  repositorio;
- que no haya secretos (contraseñas, tokens, llaves) con **gitleaks**, en los
  archivos y en todo el historial de git. Un falso positivo se acepta agregando
  su huella (`Fingerprint`) a `.gitleaksignore`.

Revisa los archivos versionados y también los nuevos aún sin `git add`. Si hay
errores, el commit no se hace. `scripts/dotfiles-install.sh` activa el hook con
`git config core.hooksPath .githooks`.

No hay CI: todo se revisa en local. Además del lint, hay dos revisiones que se
ejecutan a mano, porque tardan más:

- `scripts/check-packages.sh`, que comprueba que cada paquete de `packages.txt`
  exista en los repositorios (con RPM Fusion y los de `etc/yum.repos.d`) y que
  ninguno esté repetido, porque un nombre mal escrito haría fallar todo el
  `dnf install` (después de cambiar `packages.txt`);
- `scripts/check-install.sh`, que ejecuta `dotfiles-install.sh` dos veces en un
  `$HOME` temporal y vacío, y comprueba que la segunda no cambie nada y que no
  queden enlaces rotos (después de cambiar `dotfiles-install.sh` o
  `scripts/lib/links.sh`). Corre sin la sesión del usuario (sin D-Bus y con
  GSettings en memoria), así que no toca GNOME, la foto de perfil,
  `systemd --user` ni el `$HOME` real.

```bash
bash scripts/lint.sh             # revisar a mano
bash scripts/check-packages.sh   # comprobar packages.txt
bash scripts/check-install.sh    # probar dotfiles-install.sh en un $HOME temporal
shfmt -w scripts/archivo.sh      # corregir el formato
git commit --no-verify           # saltar el hook en un commit puntual
```

## Respaldos

Antes de reemplazar un archivo, los scripts lo respaldan como
`<archivo>.bak.<fecha>`: `dotfiles-install.sh` (los destinos de los enlaces y
el BIOS de PlayStation), `install-minidlna.sh` (`/etc/minidlna.conf`) e
`install-docker.sh` (`/etc/docker/daemon.json`). De cada archivo se guardan los
**tres respaldos más recientes**; los más antiguos se borran al volver a
ejecutar el script. La cantidad está en `backups_keep`, en
`scripts/lib/backups.sh`.

## Desinstalar

`scripts/dotfiles-uninstall.sh` quita de `$HOME` los enlaces que apuntan a este
repositorio (los de `scripts/lib/links.sh`) y, si hay respaldos, restaura el más
reciente de cada uno. Antes desactiva el timer del saludo matutino. Lo que no es
un enlace al repositorio no se toca. Pide confirmación; con `--si`, no.

```bash
bash scripts/dotfiles-uninstall.sh
```

No deshace el resto de la instalación: paquetes, servicios, grupos, PostgreSQL,
ajustes de GNOME y de Ptyxis, fuentes, la configuración de RetroArch,
`~/.pgpass`, `~/.config/git/allowed_signers` ni `npmrc-effective`.
