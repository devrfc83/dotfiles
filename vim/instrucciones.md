# Usando VIM

## Guía de configuración y uso de Vim

Esta guía explica cómo instalar y usar Vim con mi configuración actual.

### Instalación

En Fedora Linux, usa:

```bash
sudo dnf install -y vim
```

Para verificar que funciona:

```bash
which vim
vim --version
```

Toma nota de la versión.

Copia el archivo vimrc a `$HOME/.vimrc` y habilita los plugins.

Crea también los siguientes directorios:

```bash
mkdir -p $HOME/.vim/backup
mkdir -p $HOME/.vim/swap
mkdir -p $HOME/.vim/undodir
mkdir -p $HOME/.vim/snippets
```

### Plugins

Esta configuración usa el sistema nativo `pack` de Vim e incluye los siguientes plugins:

- Fugitive
- NERDCommenter
- NERDTree
- EditorConfig
- Surround
- vim-snippets
- UltiSnips
- Emmet
- EasyMotion
- Highlighted Yank
- EasyAlign
- EasyMotion
- gitgutter
- undotree
- vim-airline
- vim-endwise
- vim-test
- ALE
- YouCompleteMe

#### En Vim 8.2+

Crea los siguientes directorios:

```bash
mkdir -p $HOME/.vim/pack/themes/start
mkdir -p $HOME/.vim/pack/plugins/start
```

Instala el paquete de esquemas de color y los plugins (`cobalt` de `vimrc` está en `colors/cobalt.vim` de flazz/vim-colorschemes):

```bash
git clone https://github.com/flazz/vim-colorschemes.git $HOME/.vim/pack/themes/start/colorschemes
git clone https://github.com/preservim/nerdtree.git $HOME/.vim/pack/plugins/start/nerdtree
git clone https://github.com/preservim/nerdcommenter.git $HOME/.vim/pack/plugins/start/nerdcommenter
git clone https://github.com/tpope/vim-fugitive.git $HOME/.vim/pack/plugins/start/fugitive
git clone https://github.com/editorconfig/editorconfig-vim.git $HOME/.vim/pack/plugins/start/editorconfig
git clone https://tpope.io/vim/surround.git $HOME/.vim/pack/plugins/start/surround
git clone https://github.com/honza/vim-snippets.git $HOME/.vim/pack/plugins/start/vim-snippets
git clone https://github.com/SirVer/ultisnips.git $HOME/.vim/pack/plugins/start/ultisnips
git clone https://github.com/ycm-core/YouCompleteMe.git $HOME/.vim/pack/plugins/start/youcompleteme
git clone https://github.com/mattn/emmet-vim.git $HOME/.vim/pack/plugins/start/emmet-vim
git clone https://github.com/machakann/vim-highlightedyank.git $HOME/.vim/pack/plugins/start/highlightedyank
git clone https://github.com/junegunn/vim-easy-align.git $HOME/.vim/pack/plugins/start/easyalign
git clone https://github.com/easymotion/vim-easymotion.git $HOME/.vim/pack/plugins/start/easymotion
git clone https://github.com/airblade/vim-gitgutter.git $HOME/.vim/pack/plugins/start/gitgutter
git clone https://github.com/vim-scripts/undotree.vim.git $HOME/.vim/pack/plugins/start/undotree
git clone https://github.com/vim-airline/vim-airline.git $HOME/.vim/pack/plugins/start/airline
git clone https://github.com/tpope/vim-endwise.git $HOME/.vim/pack/plugins/start/endwise
git clone https://github.com/vim-test/vim-test.git $HOME/.vim/pack/plugins/start/vim-test
git clone https://github.com/dense-analysis/ale.git $HOME/.vim/pack/plugins/start/ale
```

### Conceptos básicos de Vim

#### Cómo salir de Vim

En modo normal, puedes salir presionando **ESC** y escribiendo `:q!`.

| Acción          | Atajo  |
| --------------- | ------ |
| Guardar         | `:w!`  |
| Salir           | `:q`   |
| Guardar y salir | `:wq!` |
| Forzar salida   | `:q!`  |

`,` es tu **tecla líder**. Debes presionar **ESC** antes de ingresar atajos. La tecla **ESC** te permite entrar en un modo donde puedes escribir comandos sin insertar texto.

#### Modos de Vim

Al comenzar a trabajar con Vim, empiezas en "modo normal", donde puedes navegar archivos y ejecutar comandos.

| Modo      | Qué hace           |
| --------- | ------------------ |
| NORMAL    | Navegar y comandos |
| INSERCIÓN | Escribir texto     |
| VISUAL    | Seleccionar texto  |
| COMANDO   | Ejecutar comandos  |

Para entrar en modo INSERCIÓN y poder escribir, presiona la letra `i`.
Para volver al modo NORMAL, presiona la tecla `ESC`.

#### Movimiento

En modo NORMAL, puedes navegar el documento con las siguientes teclas:

| Acción    | Tecla |
| --------- | ----- |
| izquierda | `h`   |
| derecha   | `l`   |
| abajo     | `j`   |
| arriba    | `k`   |

También puedes usar las teclas de flecha, pero usar estas te permite entender los siguientes atajos personalizados para moverte más rápido:

| Acción                   | Teclas |
| ------------------------ | ------ |
| bajar 8 líneas           | `,j`   |
| subir 8 líneas           | `,k`   |
| ir al inicio de la línea | `,h`   |
| ir al final de la línea  | `,l`   |

Para saltar entre partes del archivo:

| Acción             | Teclas |
| ------------------ | ------ |
| inicio del archivo | `gg`   |
| final del archivo  | `G`    |
| siguiente palabra  | `w`    |
| palabra anterior   | `b`    |
| inicio de línea    | `0`    |
| final de línea     | `$`    |

#### Edición de texto

Eliminar texto:

| Acción                  | Teclas |
| ----------------------- | ------ |
| eliminar carácter       | `x`    |
| eliminar 5 caracteres   | `5x`   |
| eliminar línea          | `dd`   |
| eliminar 5 líneas       | `5dd`  |
| eliminar palabra        | `dw`   |
| eliminar 5 palabras     | `5dw`  |
| eliminar hasta el final | `d$`   |

"Eliminar" quita el texto, pero el resultado va al portapapeles y puede pegarse.

| Acción          | Teclas |
| --------------- | ------ |
| copiar línea    | `yy`   |
| copiar 5 líneas | `5yy`  |
| pegar abajo     | `p`    |
| pegar arriba    | `P`    |

Buscar texto escribiendo `/palabra` en modo normal.

| Acción                          | Teclas |
| ------------------------------- | ------ |
| siguiente coincidencia (abajo)  | `n`    |
| siguiente coincidencia (arriba) | `N`    |
| limpiar resaltado               | `,/`   |

### Divisiones y ventanas

Cada división crea una nueva ventana.

| Acción              | Teclas |
| ------------------- | ------ |
| división vertical   | `,v`   |
| división horizontal | `,s`   |

Moverse entre ventanas con `,w` y la dirección:

| Acción          | Teclas |
| --------------- | ------ |
| mover izquierda | `,wh`  |
| mover derecha   | `,wl`  |
| mover abajo     | `,wj`  |
| mover arriba    | `,wk`  |

Redimensionar ventanas:

| Acción          | Teclas |
| --------------- | ------ |
| aumentar ancho  | `,>`   |
| disminuir ancho | `,<`   |
| aumentar alto   | `,+`   |
| disminuir alto  | `,-`   |

Trabajar con pestañas:

| Acción            | Teclas |
| ----------------- | ------ |
| nueva pestaña     | `,tn`  |
| cerrar pestaña    | `,tc`  |
| solo esta pestaña | `,to`  |
| siguiente pestaña | `,tt`  |
| pestaña anterior  | `,tT`  |

#### EasyMotion

[EasyMotion](https://github.com/easymotion/vim-easymotion) resalta posibles destinos en pantalla para que puedas saltar allí escribiendo una etiqueta corta.

El prefijo predeterminado es `<Leader><Leader>` — con la tecla líder de esta configuración (`,`), presiona la coma **dos veces**, luego la tecla de movimiento:

| Acción                                                          | Teclas         |
| --------------------------------------------------------------- | -------------- |
| Saltar a cualquier palabra adelante / atrás en pantalla         | `,,w` / `,,b`  |
| Lo mismo para una PALABRA (secuencia sin espacios)              | `,,W` / `,,B`  |
| Saltar al final de palabra adelante / atrás                     | `,,e` / `,,ge` |
| Buscar un carácter (cualquier dirección), luego elegir etiqueta | `,,s`          |
| Encontrar carácter adelante / atrás en línea (como `f` / `F`)   | `,,f` / `,,F`  |
| Hasta carácter adelante / atrás (como `t` / `T`)                | `,,t` / `,,T`  |
| Saltar a línea abajo / arriba                                   | `,,j` / `,,k`  |
| Saltar a siguiente / anterior coincidencia de búsqueda          | `,,n` / `,,N`  |

### NERDTree (Explorador de archivos)

El explorador de archivos divide la ventana actual.

| Acción                  | Teclas |
| ----------------------- | ------ |
| abrir árbol de archivos | `,nt`  |

Dentro de NERDTree:

| Acción                 | Teclas |
| ---------------------- | ------ |
| abrir archivo          | `o`    |
| abrir en nueva pestaña | `t`    |
| división horizontal    | `s`    |
| división vertical      | `v`    |
| menú de archivo        | `m`    |
| ayuda                  | `?`    |

### NERDCommenter

Estas acciones funcionan en modo NORMAL.

| Acción          | Teclas |
| --------------- | ------ |
| comentar código | `,cc`  |
| descomentar     | `,cu`  |
| alternar        | `,cc`  |

### YouCompleteMe

Instalar YouCompleteMe no es tan directo como otros plugins.

```bash
cd $HOME/.vim/pack/plugins/start/youcompleteme
git submodule update --init --recursive
sudo dnf install -y python3-devel cmake gcc-c++
python3 install.py --ts-completer
```

### vim-test

Estos atajos están configurados en `vimrc` con `vim-test`:

| Acción                     | Teclas |
| -------------------------- | ------ |
| ejecutar test más cercano  | `,rt`  |
| ejecutar tests del archivo | `,rf`  |
| ejecutar suite completa    | `,rs`  |
| repetir último test        | `,rl`  |
| saltar al último test      | `,rv`  |

### Integración con Git (vim-fugitive)

Dentro de un repositorio Git:

| Acción           | Comando     |
| ---------------- | ----------- |
| abrir estado     | `:Git`      |
| preparar archivo | `-`         |
| confirmar        | `cc`        |
| ver diferencias  | `:Git diff` |
