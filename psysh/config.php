<?php

// Configuración de PsySH, el REPL de PHP que abre «php artisan tinker» (Laravel
// trae PsySH en vendor/ de cada proyecto). Se enlaza en ~/.config/psysh/config.php.
//
// Tema Dracula con los colores de scripts/lib/dracula.palette (lint lo revisa),
// como en el resaltado de PHP de Dracula: palabras clave rosadas, cadenas
// amarillas, números y constantes morados, clases cyan, funciones verdes y
// comentarios grises. Cada estilo es [texto, fondo, [opciones]]; los que faltan
// toman el valor por defecto de PsySH.

return [
    'theme' => [
        // Indicadores del tema «modern» de PsySH (el de fábrica)
        'prompt' => '> ',
        'bufferPrompt' => '. ',
        'replayPrompt' => '- ',
        'returnValue' => '= ',
        'styles' => [
            // Mensajes
            'info' => ['#50fa7b', null, ['bold']],
            'warning' => ['#282a36', '#ffb86c'],
            'error' => ['#f8f8f2', '#ff5555', ['bold']],
            'whisper' => ['#6272a4'],
            'aside' => ['#6272a4'],
            'strong' => [null, null, ['bold']],
            'return' => ['#8be9fd'],
            'urgent' => ['#ff5555'],
            'hidden' => ['#44475a'],
            'command' => ['#8be9fd', null, ['bold']],
            'command_option' => ['#ffb86c'],
            'command_argument' => ['#50fa7b'],

            // Visibilidad y nombres (ls, doc, show)
            'public' => [null, null, ['bold']],
            'protected' => ['#ffb86c'],
            'private' => ['#ff5555'],
            'global' => ['#bd93f9', null, ['bold']],
            'const' => ['#bd93f9'],
            'class' => ['#8be9fd', null, ['underscore']],
            'function' => ['#50fa7b'],
            'virtual' => ['#ff79c6'],
            'default' => [null],

            // Valores y código
            'number' => ['#bd93f9'],
            'integer' => ['#bd93f9'],
            'float' => ['#bd93f9'],
            'string' => ['#f1fa8c'],
            'array_key' => ['#8be9fd'],
            'bool' => ['#bd93f9'],
            'keyword' => ['#ff79c6'],
            'comment' => ['#6272a4'],
            'code_comment' => ['#6272a4'],
            'object' => ['#8be9fd'],
            'resource' => ['#ffb86c'],
            'inline_html' => ['#f8f8f2'],

            // Línea de entrada
            'input_frame' => ['#f8f8f2', '#44475a'],
            'input_frame_error' => ['#f8f8f2', '#ff5555'],
            'input_highlight' => [null, null, ['reverse']],
        ],
    ],
];
