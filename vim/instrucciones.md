# Usando VIM

## Guía de configuración y uso de Vim

Esta guía explica cómo instalar y usar Vim con la configuración de este repositorio.

### Instalación

En Fedora Linux se instala con el siguiente comando (`vim-X11` trae `vimx`, el Vim con portapapeles del sistema):

```bash
sudo dnf install -y vim vim-X11
```

Para verificar que funciona:

```bash
which vim
vim --version
```

Conviene anotar la versión. `vim --version | grep clipboard` debe mostrar `+clipboard`; si muestra `-clipboard`, falta el enlace `~/.local/bin/vim` → `/usr/bin/vimx` que crea `scripts/dotfiles-install.sh`.

`scripts/dotfiles-install.sh` enlaza el `vimrc` en `$HOME/.vimrc` y crea los directorios de trabajo (`~/.vim/backup`, `swap`, `undodir` y `snippets`).

### Plugins

Esta configuración usa el sistema nativo `pack` de Vim e incluye los siguientes plugins:

- Fugitive
- NERDCommenter
- NERDTree
- EditorConfig (incluido en Vim 9.2)
- Surround
- vim-snippets
- UltiSnips
- Emmet
- EasyMotion
- hlyank (resaltar lo copiado; incluido en Vim 9.2)
- EasyAlign
- gitgutter
- undotree
- vim-airline
- vim-endwise
- vim-test
- ALE
- YouCompleteMe

#### Instalación y actualización

El esquema de colores (`cobalt`, de flazz/vim-colorschemes) y los plugins se instalan o actualizan con:

```bash
bash scripts/install-vim-plugins.sh
```

Clona en `~/.vim/pack/` lo que falte, actualiza lo que ya existe y regenera la ayuda de los plugins. La lista de repositorios está al principio del script. EditorConfig y hlyank no se clonan: vienen con Vim 9.2 y el `vimrc` los activa con `packadd!`.

### Conceptos básicos de Vim

#### Cómo salir de Vim

Para salir sin guardar, debe presionarse **ESC** y escribirse `:q!`.

| Acción          | Atajo  |
| --------------- | ------ |
| Guardar         | `:w`   |
| Salir           | `:q`   |
| Guardar y salir | `:wq`  |
| Forzar salida   | `:q!`  |

`,` es la **tecla líder**. Antes de usar un atajo debe presionarse **ESC**, que vuelve al modo normal, donde las teclas se interpretan como comandos y no como texto.

#### Modos de Vim

Vim arranca en «modo normal», donde se navega por el archivo y se ejecutan comandos.

| Modo      | Qué hace           |
| --------- | ------------------ |
| NORMAL    | Navegar y comandos |
| INSERCIÓN | Escribir texto     |
| VISUAL    | Seleccionar texto  |
| COMANDO   | Ejecutar comandos  |

Para escribir texto se pasa al modo INSERCIÓN con la tecla `i`.
Para volver al modo NORMAL se presiona `ESC`.

#### Movimiento

En modo NORMAL, el documento se recorre con las siguientes teclas:

| Acción    | Tecla |
| --------- | ----- |
| izquierda | `h`   |
| derecha   | `l`   |
| abajo     | `j`   |
| arriba    | `k`   |

También sirven las flechas, pero estas teclas son la base de los siguientes atajos personalizados para moverse más rápido:

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

Para buscar texto se escribe `/palabra` en modo normal.

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

[EasyMotion](https://github.com/easymotion/vim-easymotion) resalta los destinos posibles en pantalla; para saltar a uno se escribe su etiqueta corta.

El prefijo predeterminado es `<Leader><Leader>` — con la tecla líder de esta configuración (`,`), se presiona la coma **dos veces** y luego la tecla de movimiento:

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

| Acción          | Teclas        |
| --------------- | ------------- |
| comentar código | `,cc`         |
| descomentar     | `,cu`         |
| alternar        | `,c<Espacio>` |

### YouCompleteMe

YouCompleteMe necesita compilarse. `scripts/install-vim-plugins.sh` lo hace la primera vez y cada vez que el plugin se actualiza, usando `python3-devel`, `cmake` y `gcc-c++` (en `packages.txt`). Si encuentra Node (nvm), agrega el completado de TypeScript (`--ts-completer`).

En esta configuración YouCompleteMe solo completa; los errores y advertencias los muestra ALE.

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
