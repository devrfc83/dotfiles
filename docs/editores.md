# Editores

Vim, vimdiff, VSCodium, Cursor, Zed, opencode y EditorConfig.

[← Volver al índice](README.md)

## Vim

Los directorios de trabajo (`~/.vim/backup`, `swap`, `undodir` y `snippets`) los
crea `scripts/dotfiles-install.sh`. El esquema de colores y los plugins (sistema
`pack` de Vim) los instala o actualiza:

```bash
bash scripts/install-vim-plugins.sh
```

El script clona en `~/.vim/pack/` lo que falte, actualiza con `git pull` lo que
ya existe, compila **YouCompleteMe** cuando hace falta (la primera vez, cuando
cambió o cuando cambiaron sus opciones de compilación; con completado de Rust,
que usa el rust-analyzer que descarga YouCompleteMe, y de TypeScript si
encuentra Node de fnm) y regenera la ayuda (`:help`) de los plugins. Lo ejecuta
también `scripts/extras-install.sh`. Las dependencias de compilación
(`python3-devel`, `cmake`, `gcc-c++`) están en `packages.txt`.

En el `vimrc` de este repositorio se usa `colorscheme dracula`, el tema oficial
[dracula/vim](https://github.com/dracula/vim), que también trae el de airline.
La lista de plugins y
su uso se documentan en `vim/instrucciones.md`.

El enlace `~/.vimrc` → `vim/vimrc` debe existir ([Enlazar los
dotfiles](instalacion.md#enlazar-los-dotfiles)).

**Portapapeles (vimx):** el `vim` de Fedora (`vim-enhanced`) está compilado sin
portapapeles (`-clipboard`), así que `set clipboard=unnamedplus` no tendría
efecto. Por eso se instala `vim-X11` (bloque DNF), que trae `vimx`: el mismo Vim
en terminal, con `+clipboard`. En GNOME con Wayland usa directamente el
portapapeles de Wayland (`+wayland_clipboard`, Vim 9.2), y lo copiado sigue
disponible al cerrar Vim.

Para usarlo con los nombres de siempre, `scripts/dotfiles-install.sh` crea en
`~/.local/bin` (que va primero en el `PATH`) los enlaces `vim`, `vi`, `vimdiff`
y `view` hacia `/usr/bin/vimx`. Vim elige el modo según el nombre con que se
invoca: `vimdiff` compara archivos y `view` abre en solo lectura. `EDITOR`,
`VISUAL` y `core.editor` de git apuntan directamente a `/usr/bin/vimx`.

Para comprobarlo: `vim --version | grep clipboard` debe mostrar `+clipboard`.

**Valores por defecto:** el `vimrc` carga `$VIMRUNTIME/defaults.vim` (Vim no lo
hace solo si existe `~/.vimrc`), que aporta `ttimeoutlen` (Esc sin demora),
`incsearch`, `wildmenu`, `showcmd` y `filetype plugin indent on`.

**Formato al guardar (ALE):** prettier (CSS, HTML, JS, JSON, SCSS, TS, Vue),
pint (PHP), ruff (Python; paquete `ruff` del bloque DNF), rustfmt, shfmt y
pgFormatter (SQL). prettier y pint se buscan en `node_modules/.bin` y
`vendor/bin` de cada proyecto; si un formateador no está instalado, ALE lo omite
sin error.

## Vimdiff

**vimdiff** es el modo diff de Vim; no se instala por separado. Sirve para
comparar dos o más archivos en terminal:

```bash
vimdiff archivo1 archivo2
# o
vim -d archivo1 archivo2
```

Se usa la misma configuración que `~/.vimrc`.

## VSCodium

VSCodium y Cursor no están en los repos de Fedora; cada uno tiene su repositorio
RPM. Los archivos `.repo` están versionados en `etc/yum.repos.d/` y
`scripts/fedora-install.sh` los instala, junto con sus llaves GPG, antes del
bloque DNF (`codium` y `cursor` están en `packages.txt`). Las llaves solo se
importan si su huella coincide con la esperada:

| Repositorio | Llave                                                 | Huella                                               |
| ----------- | ----------------------------------------------------- | ---------------------------------------------------- |
| VSCodium    | Pavlo Rudyi (mantenedor del repo RPM de VSCodium)     | `1302 DE60 2318 89FE 1EBA  CADC 5467 8CF7 5A27 8D9C` |
| Cursor      | Anysphere Inc (empresa de Cursor)                     | `380F F4BC DC34 A4BD 92A3  5653 42A1 772E 62E4 92D6` |

A mano, sin el script:

```bash
sudo rpm --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
sudo rpm --import https://downloads.cursor.com/keys/anysphere.asc
sudo install -m 644 etc/yum.repos.d/vscodium.repo etc/yum.repos.d/cursor.repo /etc/yum.repos.d/
sudo dnf install -y codium cursor
```

En `zsh/zshenv`, `EDITOR` y `VISUAL` apuntan siempre a `vimx` (Vim con
portapapeles; ver [Vim](#vim)), igual que `core.editor` en `git/gitconfig`.
Codium se
sigue usando como `difftool` y `mergetool` de git.

**Configuración:** `codium/settings.json` (VSCodium) y
`codium/cursor-settings.json` (Cursor) se enlazan en
`~/.config/<editor>/User/settings.json` con `scripts/dotfiles-install.sh`; los
cambios hechos desde la interfaz de cada editor quedan en el repositorio. Los
dos archivos son iguales, salvo que Cursor sigue el tema claro u oscuro de GNOME
y VSCodium conserva sus ajustes propios (panel de Claude Code, sin pantalla de
inicio y Python con basedpyright como único servidor de lenguaje y Ruff como
formateador):

- **Formato al guardar:** PHP con **Pint** (respeta el `pint.json` del proyecto;
  sin él, usa el preset de Laravel) y el resto (CSS, HTML, JS/TS, JSON, SCSS,
  Vue, YAML) con **Prettier**.
- **PHP:** solo Intelephense (se desactiva el soporte integrado del editor, que
  duplicaba sugerencias).
- **Fuentes:** FiraCode Nerd Font con ligaduras en el editor; FiraCode Nerd Font
  Mono en la terminal integrada.
- **Reglas de longitud:** columna 132 (80 en Markdown), como en `editorconfig`.
- **Exclusiones:** `vendor/`, `cache/` y `versions/` quedan fuera de las
  búsquedas y de Ctrl+P, como en el `wildignore` de Vim.
- **Telemetría de Red Hat** desactivada (extensión de XML).

En la terminal integrada no se muestra fastfetch (`zsh/zshrc` lo omite cuando
`TERM_PROGRAM=vscode`).

**Extensiones:** la lista está en `codium/extensions.txt` y sirve para los dos
editores; una segunda columna limita una extensión a uno solo (Claude Code,
GitLens, Bruno, las de Python y el soporte de idioma de Intelephense van solo en
Codium; Cursor trae su propio soporte de Python).
`scripts/install-editor-extensions.sh` instala en Codium y en Cursor las que
falten (lo ejecuta también `extras-install.sh`); si una falla, sigue con las
demás y lo informa al final.

| Extensión                                     | Uso                                        |
| --------------------------------------------- | ------------------------------------------ |
| `anthropic.claude-code`                       | Claude Code (solo Codium)                  |
| `anessaeah.php-intelephense-language-support` | Soporte de idioma PHP (solo Codium)        |
| `bmewburn.vscode-intelephense-client`         | PHP (Intelephense)                         |
| `bruno-api-client.bruno`                      | Cliente de API Bruno (solo Codium)         |
| `charliermarsh.ruff`                          | Python: Ruff, lint y formato (solo Codium) |
| `dart-code.dart-code`                         | Dart                                       |
| `dart-code.flutter`                           | Flutter                                    |
| `dbaeumer.vscode-eslint`                      | ESLint                                     |
| `detachhead.basedpyright`                     | Python: tipos y completado (solo Codium)   |
| `doonfrs.livewire-support`                    | Livewire                                   |
| `dsznajder.es7-react-js-snippets`             | Snippets React/JS                          |
| `eamodio.gitlens`                             | GitLens (solo Codium)                      |
| `editorconfig.editorconfig`                   | EditorConfig                               |
| `esbenp.prettier-vscode`                      | Formato con Prettier                       |
| `laravel.vscode-laravel`                      | Laravel                                    |
| `mikestead.dotenv`                            | Archivos `.env`                            |
| `ms-python.debugpy`                           | Python: depurador (solo Codium)            |
| `ms-python.python`                            | Python: entornos y ejecución (solo Codium) |
| `mtxr.sqltools`                               | SQLTools                                   |
| `mtxr.sqltools-driver-pg`                     | Driver PostgreSQL para SQLTools            |
| `open-southeners.laravel-pint`                | Laravel Pint                               |
| `porifa.laravel-intelephense`                 | Laravel en Intelephense                    |
| `prince781.vala`                              | Vala                                       |
| `redhat.vscode-xml`                           | XML                                        |
| `rust-lang.rust-analyzer`                     | Rust (rust-analyzer; formato con rustfmt)  |
| `timsexperiments.vscode-tailwindcss`          | Tailwind CSS                               |

Para comprobar o actualizar las extensiones:

```bash
codium --list-extensions    # o: cursor --list-extensions
codium --update-extensions  # o: cursor --update-extensions
```

## Zed

Zed no está en los repos de Fedora (solo en Terra, un repositorio de la
comunidad, y en Flathub). `scripts/install-zed.sh` (lo ejecuta
`extras-install.sh`) usa el instalador oficial, que lo deja en
`~/.local/zed.app`, con el enlace `~/.local/bin/zed` y su entrada en el menú de
aplicaciones. Si ya está instalado no hace nada: Zed se actualiza solo. El
instalador descarga por HTTPS sin verificar checksums, como el de rustup.

**Configuración:** `zed/settings.json` se enlaza en
`~/.config/zed/settings.json`; los cambios hechos desde la interfaz quedan en el
repositorio. Sigue los mismos criterios que VSCodium:

- **Tema:** Dracula, con la extensión oficial
  ([dracula/zed](https://github.com/dracula/zed)).
- **Extensiones:** Zed instala solo, al abrirse, las de
  `auto_install_extensions`: `dracula`, `dockerfile`, `php`, `sql`, `vala` y
  `xml`. Rust, Python, TypeScript y Go vienen con Zed.
- **Fuentes:** FiraCode Nerd Font con ligaduras en el editor; FiraCode Nerd Font
  Mono en la terminal integrada.
- **Reglas de longitud:** columna 132 (80 en Markdown), con ajuste de línea
  visual en la misma columna.
- **Formato al guardar** activado, con el formateador de cada lenguaje.
- **Telemetría** desactivada (diagnósticos y métricas).

**opencode dentro de Zed:** Zed conecta agentes externos con ACP (*Agent Client
Protocol*). Para usar [opencode](#opencode) en el panel de agentes de Zed:
`agent: open settings` (paleta de órdenes) → **External Agents** → **Add
Agent** → **Install from Registry** → OpenCode. Zed recomienda instalarlo
desde su registro y no escribirlo a mano en `agent_servers`; opencode usa su
propia sesión y sus propios modelos.

## opencode

opencode es un agente de programación para la terminal. No está en Fedora:
`scripts/install-opencode.sh` (lo ejecuta `extras-install.sh`, así que
`dotfiles-update.sh` también lo actualiza) usa el instalador oficial con
`--no-modify-path`, que deja el binario en `~/.opencode/bin` sin tocar
`~/.zshrc`; ese directorio lo agrega al `PATH` `zsh/zshenv`. Si ya está la
última versión, el instalador no descarga nada. Como el de Zed, descarga por
HTTPS sin verificar checksums.

**Configuración** (en `~/.config/opencode/`, enlaces a `opencode/`):

- `tui.json`: la interfaz. Tema `dracula`, que viene incluido en opencode (en
  opencode 2 el tema va aquí, no en `opencode.json`).
- `opencode.json`: la configuración global, que se combina con el
  `opencode.json` de cada proyecto. Pregunta antes de editar archivos y de
  ejecutar órdenes (`permissions`; el formato anterior, `permission`, quedó
  obsoleto en opencode 2).

## EditorConfig

No se requiere paquete: basta con el enlace `~/.editorconfig` →
`editorconfig/editorconfig`. Los editores con soporte EditorConfig leerán las
reglas al abrir un proyecto. El repositorio tiene además su propio
`.editorconfig` (un enlace al mismo archivo), para que sus reglas valgan recién
clonado, antes de `dotfiles-install.sh`. Vim y Zed usan el archivo
directamente; Codium y Cursor usan la extensión EditorConfig de la tabla
anterior.
