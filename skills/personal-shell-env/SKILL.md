---
name: personal-shell-env
description: >-
  Mi entorno de terminal (Fedora, zsh, git): alias de git y de zsh, programas
  instalados y cómo evitar que los alias interactivos (cp -i, ls con eza,
  pagers, comandos que no terminan) bloqueen o confundan a Claude. Úsala en
  cualquier proyecto al ejecutar comandos de shell o git.
---

# Mi entorno de terminal

Estoy en Fedora con zsh y oh-my-zsh. Mis alias, funciones y opciones están
pensados para mi terminal interactiva; no para ti. Antes de ejecutar comandos,
usa las versiones de esta skill.

## Regla base

Usa el comando real, no el alias de zsh, salvo que el alias sea de git (esos
funcionan en todos mis repos). Si dudas, antepón `command`: `command cp` salta
cualquier alias y funciona igual en bash y zsh.

## Quirks que bloquean o confunden

- **`cp`, `mv` y `rm` tienen `-i`.** En mi terminal preguntan antes de
  sobrescribir o borrar, y esperan una respuesta que nunca llega. Usa `command
  cp`, `command mv` y `command rm`, sin `-i`. Para borrar, confirma antes con la
  lista de lo que se borra.
- **`ls` es `eza` con iconos y colores.** La salida no es fácil de parsear. Para
  listados que vas a procesar, usa `command ls -la` o `/bin/ls`.
- **`grep` tiene `--color` forzado.** Mete secuencias de color en la salida al
  encadenar comandos. Usa `command grep` o, mejor, `rg`.
- **El paginador es `most` y git usa `delta`.** En una ejecución sin terminal,
  un paginador se queda esperando. Usa `git --no-pager ...` y `command cat` o
  `bat --paging=never`.
- **Comandos que no terminan:** `t` (`tail -f`), `www` (servidor HTTP en 8000),
  `pglog` (`journalctl -f`), `ncdu`, `btop`, `mc`, `fzf`, `tmux`, `screen`. No
  los ejecutes en una sesión de Claude; usa la versión sin seguimiento (`tail -n
  100`, `du -sh`, etc.).
- **Prompts que esperan respuesta:**
  - `git ci` sin `-m` abre el editor. Usa siempre `git ci -m "..."`.
  - `git rebase --continue` y similares pueden abrir el editor: antepón
    `GIT_EDITOR=true`.
  - Git con `help.autocorrect = prompt` pregunta si un comando está mal escrito.
    Escribe bien los comandos.
  - zsh con `CORRECT` y `ENABLE_CORRECTION` también puede preguntar. Escribe
    bien los comandos.
- **Globs de zsh.** `NO_MATCH` hace que un patrón sin coincidencias falle en
  zsh, pero en bash pasa como literal. Si un comando no encuentra archivos,
  revisa el patrón antes de reintentar.
- **`sudo` con alias.** `please`, `fuck`, `shit` y `root` llaman a sudo. No los
  uses: pide el comando explícito y deja que yo lo ejecute.
- **`$PAGER` y `$EDITOR`** son `most` y `/usr/bin/vimx`. Si un programa abre el
  editor o el paginador, define `EDITOR=true` o `PAGER=cat` para esa ejecución.

## Alias de git (`git/gitconfig`)

Estos funcionan en cualquier repositorio, también en los de clientes. Usa el
alias en lugar del comando largo.

| En lugar de | Usa | Qué hace |
| --- | --- | --- |
| `git add -A` | `git all` | Agrega todo, incluidos borrados y nuevos |
| `git add <archivo>` | `git a <archivo>` | Agrega archivos concretos |
| `git commit -S -s -m "..."` | `git ci -m "..."` | Commit firmado por SSH con `Signed-off-by` |
| `git commit --amend` | `git cia` | Enmienda el último commit |
| `git commit --amend --no-edit` | `git cian` | Enmienda sin cambiar el mensaje |
| `git commit --allow-empty` | `git cie` | Commit vacío firmado |
| `git push` | `git ps` | Push normal; crea el upstream solo |
| `git push --force-with-lease --force-if-includes` | `git psf` | Push forzado seguro |
| `git push --force-with-lease=<rama>:<punta remota>` | `git psr [remotos]` | Push forzado seguro después de `git rfc` |
| `git push --set-upstream` | `git psu` | Fija el upstream |
| `git pull --rebase` | `git pr` | Pull con rebase |
| `git pull` | `git pl` | Pull (solo fast-forward) |
| `git pull --dry-run` | `git plt` | Ver qué traería el pull |
| `git merge --no-edit` | `git m` | Merge sin editor |
| `git status` | `git s` | Estado |
| `git fetch --all` | `git fa` | Trae todos los remotos |
| `git fetch origin` | `git fi` | Trae de origin |
| `git switch` / `git checkout` | `git sw` / `git co` | Cambiar de rama |
| `git branch -d <rama>` | `git bd` | Borrar rama fusionada |
| `git reset HEAD^` | `git uc` | Deshace el último commit y conserva los cambios |
| `git reset --soft HEAD@{1}` | `git uca` | Deshace la última acción de reset o amend |
| `git reset HEAD --` | `git unstage` | Saca archivos del área de preparación |
| `git rebase -i` | `git rbi` | Rebase interactivo (con autosquash) |
| `git rebase --continue` / `--abort` / `--skip` | `git rbc` / `git rba` / `git rbs` | Continuar, abortar o saltar |
| `git stash` | `git st` | **Ojo: es stash, no status** |
| `git stash pop` / `apply` / `list` / `drop` / `clear` | `git stp` / `git sta` / `git stl` / `git std` / `git stc` | Gestión de stash |
| `git log --oneline` | `git l` | Historial compacto |
| `git log --graph ...` con colores | `git lg` | Historial con grafo |
| `git log --graph --date=short ...` | `git hist` | Historial con fechas y autor |
| `git blame` | `git bl` | Autor de cada línea |
| `git diff` | `git df` | Diferencias |
| `git difftool` | `git dt` | Diferencias en VSCodium |
| `git rev-parse --show-toplevel` | `git root` | Raíz del repositorio |
| `git clean -df` | `git cl` | Borra archivos sin seguimiento |
| `git remote -v` | `git remotes` | Remotos con URL |
| `git init` | `git new` | Crea el repositorio |
| `git shortlog -s -n --no-merges` | `git who` | Autores por número de commits |
| `git shortlog --since=yesterday` | `git standup` | Lo hecho desde ayer |

Advertencias de git:

- **`git psf` y `git psr` reescriben la historia remota.** Úsalos solo si lo
  pido, y nunca en `main` ni en otra rama compartida sin confirmarlo, salvo en
  repositorios cuya skill diga lo contrario (como los dotfiles). Después de
  `git rfc` usa `git psr`: `git psf` siempre rechaza, porque
  `--force-if-includes` descarta los commits con fecha anterior a la última
  actualización de la rama remota.
- **`git clean -df` borra sin preguntar.** Antes muestra `git clean -dn`
  (simulación) y confirma.
- **`git rfc` cambia la fecha de los commits a 1983.** No lo uses salvo que lo
  pida o que la skill del repositorio lo indique (como los dotfiles).
- **`git ci` firma con mi llave SSH.** Si la firma falla, avísame; no cambies a
  un commit sin firma.
- **`git ci` agrega `Signed-off-by`.** En proyectos de clientes que no lo usan,
  pregunta antes.
- **Repos de Sea Dragon** (remoto `seadragon://` o `ssh://git@git.seadragon.cl`)
  usan otro correo. No cambies `user.email` a mano.

## Alias de zsh (`zsh/zshaliases`)

Solo existen en mi terminal interactiva. Esta tabla es para que sepas qué hacen;
no los uses en una sesión de Claude salvo que el comando equivalente no exista.

| Alias | Qué es | Equivalente para ti |
| --- | --- | --- |
| `cp`, `mv`, `rm` | `-i`: pregunta antes de sobrescribir o borrar | `command cp`, `command mv`, `command rm` |
| `ls`, `l`, `la`, `ll`, `lt`, `lr`, `lS`, `lsr`, `lart`, `ldot`, `lrt`, `lsn` | `eza` con iconos (si está instalado) o `ls` | `command ls -la` o `/bin/ls` |
| `grep` | `grep --color` | `command grep` |
| `t` | `tail -f` (no termina) | `tail -n 100` |
| `www` | Servidor HTTP en 8000 (no termina) | No lo uses |
| `p` | `ps -f` | `ps -f` |
| `cl`, `cls` | `clear` | No los uses |
| `h`, `hist`, `hgrep` | Historial de zsh | No aplica en shell no interactivo |
| `home` | Cambia a `$HOME` | `cd "$HOME"` |
| `mapa`, `starwars` | Juegos por red | No los uses |
| `dirsize` | `du -hsL */` | `du -hsL -- */` |
| `fixperms`, `fixpermsrestrict` | Cambian permisos recursivamente | Solo si lo pido |
| `rmemptydirs`, `rmemptyfiles` | Borran directorios y archivos vacíos | Confirma antes |
| `cdtemp`, `deltemp` | Crean y borran `~/.tmpdir` | Usa `mktemp -d` |
| `zshconfig`, `zshreload`, `ohmyzsh` | Editan o recargan zsh | No aplica |
| `pg` | `pgcli` interactivo | `psql -c "..."` (ver abajo) |
| `pgfmt` | `pg_format` para SQL | `pg_format` |
| `fzfp`, `bcat` | `fzf` con vista previa o `bat` sin paginar | `bat --style=plain --paging=never` |
| `fdh` | `fd --hidden --follow --exclude .git` | Igual |
| `denv` | `direnv allow` | `direnv allow` (solo si lo pido) |
| `android` | `android --no-metrics` | Igual |

Alias de sufijo: escribir un archivo de vídeo o audio lo abre en Showtime o
Decibels. Claude no lo necesita.

## Funciones de zsh (`zsh/zshfunctions`)

| Función | Qué hace | Cómo usarla desde Claude |
| --- | --- | --- |
| `ggg <patrón>` | Busca texto sin distinguir mayúsculas, respeta `.gitignore` con ripgrep | `rg -i -- "patrón"` |
| `fff <patrón>` | Busca archivos por nombre | `fd -i "patrón"` o `find . -iname "*patrón*"` |
| `extractfile <archivo>` | Extrae cualquier formato comprimido común | Lo mismo, con `tar`, `unzip`, `7z`, `unrar`, `zstd`, según el formato |
| `psgrep <patrón>` | Busca procesos | `ps aux \| grep -i -- "patrón" \| grep -v grep` |
| `flip <texto>` | Voltea texto | No aplica |
| `clima`, `clima-hoy`, `luna` | Consultan wttr.in en español | `curl -s "wttr.in/<ciudad>?lang=es"` |
| `pgstart`, `pgstop`, `pgstatus` | Controlan el servicio PostgreSQL con sudo | Pide el comando; no lo ejecutes tú |
| `pglog` | Sigue el log de PostgreSQL (no termina) | `journalctl -u postgresql-19 -n 200` |
| `lintsh <archivo>` | ShellCheck | `shellcheck <archivo>` |
| `fmtsh <archivo>` | shfmt escribiendo en el archivo | `shfmt -w <archivo>`, solo si lo pido |

## Programas instalados (`packages.txt`)

Antes de usar uno, comprueba con `command -v <programa>`. Cuando hay un
equivalente estándar, prefiero que lo uses.

| Programa | Úsalo para | En lugar de |
| --- | --- | --- |
| `rg` (ripgrep) | Buscar texto; respeta `.gitignore` | `grep -r` |
| `fd` | Buscar archivos por nombre | `find` |
| `bat` | Ver archivos con resaltado y sin paginar (`--paging=never`) | `cat` |
| `eza` | Listados con iconos (solo tu terminal) | `ls` |
| `delta` | Paginador de diffs de git; para leer la salida, usa `git --no-pager` | — |
| `jq` | JSON: `jq '.clave' archivo.json` | Parsear a mano |
| `yq` | YAML | Parsear a mano |
| `tokei` | Contar líneas por lenguaje | `cloc` |
| `hyperfine` | Medir tiempos con repeticiones | `time` |
| `httpie` (`http`) | Peticiones HTTP legibles | `curl` si `http` no está |
| `ncdu` | Uso de disco interactivo (no lo uses) | `du -sh -- */` |
| `gitleaks` | Buscar secretos antes de un commit | — |
| `direnv` | Variables por directorio (`direnv allow` solo si lo pido) | — |
| `zoxide` | Saltar directorios (`z`) | Rutas absolutas |
| `pgcli` / `pspg` | `psql` interactivo con autocompletado | `psql -c "..."` |
| `psql` (PostgreSQL 19) | Consultas no interactivas | Usa las variables `PGHOST`, `PGPORT`, `PGUSER`, `PGDATABASE` ya exportadas; la contraseña está en `~/.pgpass` |
| `pg_format` | Formatear SQL | — |
| `uv`, `ruff` | Python: gestor y linter/formateador | `pip` en proyectos propios |
| `composer`, `php` 8.6 | PHP y dependencias | — |
| `node`, `npm` (fnm) | Node.js | nvm (no uso nvm) |
| `go` (`/usr/local/go`) | Go, instalado desde go.dev | El RPM `golang` de Fedora |
| `shellcheck`, `shfmt` | Lint y formato de shell | — |
| `hadolint` | Lint de Dockerfile | — |
| `trivy` | Escaneo de vulnerabilidades | — |
| `docker` / `docker compose` | Contenedores (Docker CE) | — |
| `podman`, `podman-compose` | Contenedores rootless | — |
| `gh` | GitHub CLI | Web |
| `doctl` | DigitalOcean CLI | Web |
| `ansible-core`, `make` | Despliegues con Ansible | — |
| `pandoc` | Convertir documentos | — |
| `magick` (ImageMagick) | Imágenes | — |
| `tig` | Historial interactivo (no lo uses) | `git log` |
| `rsync`, `tar`, `zstd`, `unzip`, `7z`, `unrar`, `xz`, `gzip`, `bzip2` | Archivos y copias | — |
| `mkcert`, `swaks`, `nmap` | Certificados, pruebas SMTP y escaneo de red (solo con permiso) | — |

Conflicto conocido: Docker CE y Podman pueden convivir, pero nunca instales
`podman-docker` junto con Docker CE.

## Cómo aplicar esta skill

1. Para cualquier comando de archivos, usa `command cp`, `command mv`, `command
   rm` y `command ls`.
2. Para buscar, usa `rg` y `fd`, no `grep` ni `find`, si están instalados.
3. Para git, usa los alias de la tabla y `git --no-pager` cuando la salida se
   vaya a leer.
4. Nunca ejecutes comandos que no terminan (`t`, `www`, `pglog`, `ncdu`, `btop`,
   `mc`, `tmux`, `fzf`, `tig`).
5. Antes de cualquier acción destructiva (`psf`, `psr`, `clean`, `uc`, `rm`,
   `stc`, `std`), confirma conmigo.
6. Si un alias o programa no existe en esta máquina, usa el comando estándar y
   dímelo.
