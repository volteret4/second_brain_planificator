#!/usr/bin/env bash
#
# sb_search_notes.sh — Buscar y abrir nota desde hotkey AwesomeWM.
# Lanza una terminal flotante con fzf sobre ~/notes/.
# Modos:
#   (sin args)   búsqueda de contenido con rg + fzf
#   --files      búsqueda solo por nombre de archivo con fd + fzf
#
# La nota seleccionada se abre en emacsclient -n (no bloquea la terminal).
# AwesomeWM: añadir regla floating para class="sb-search".
#

VAULT="$HOME/notes"
TERM_CMD="${TERMINAL:-alacritty}"

# Si ya hay una instancia corriendo, enfocarla
if xdotool search --classname "sb-search" &>/dev/null; then
    xdotool search --classname "sb-search" windowactivate
    exit 0
fi

# -n: abre en emacsclient sin bloquear la terminal de búsqueda
OPEN_CMD='emacsclient -c -n'
OPEN_FALLBACK='hx'

if [[ "$1" == "--files" ]]; then
    cmd="fd --extension md --follow . '$VAULT'"
    preview='bat --color=always --style=numbers {} 2>/dev/null | head -80'
    bind_enter="enter:execute-silent($OPEN_CMD {} 2>/dev/null || $OPEN_FALLBACK {})+abort"
else
    cmd="rg --line-number --glob '*.md' --with-filename --color never '' '$VAULT'"
    preview='f=$(echo {} | cut -d: -f1); l=$(echo {} | cut -d: -f2);
             bat --color=always --style=numbers --highlight-line "$l" "$f" 2>/dev/null | head -80'
    bind_enter="enter:execute-silent(
        f=\$(echo {} | cut -d: -f1);
        l=\$(echo {} | cut -d: -f2);
        $OPEN_CMD +\"\$l\" \"\$f\" 2>/dev/null || $OPEN_FALLBACK +\"\$l\" \"\$f\"
    )+abort"
fi

$TERM_CMD \
    --class sb-search \
    --title "Buscar notas" \
    -e bash -c "
        eval \"$cmd\" | fzf \
            --delimiter ':' \
            --preview \"$preview\" \
            --preview-window 'right:55%:wrap' \
            --bind 'ctrl-p:toggle-preview' \
            --bind '$bind_enter' \
            --prompt 'notas> ' \
            --height 100%
    " 2>/dev/null
