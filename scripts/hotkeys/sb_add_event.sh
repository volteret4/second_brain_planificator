#!/usr/bin/env bash
#
# sb_add_event.sh — Añadir evento al calendario desde hotkey AwesomeWM.
# Abre org-capture template "e" (Evento + SCHEDULED) → org-caldav → Radicale.
# No bloquea el hotkey gracias a -n; el frame se cierra solo al C-c C-c / C-c C-k.
#

SOCKET="/run/user/$(id -u)/emacs/server"

_ensure_daemon() {
    emacsclient --socket-name="$SOCKET" -e 't' &>/dev/null && return 0
    systemctl --user restart emacs.service &>/dev/null
    for i in $(seq 20); do
        sleep 0.5
        emacsclient --socket-name="$SOCKET" -e 't' &>/dev/null && return 0
    done
    return 1
}

if _ensure_daemon; then
    emacsclient --socket-name="$SOCKET" -c -n -e '(org-capture nil "e")'
else
    notify-send -i dialog-error "Second Brain" "No se pudo arrancar el daemon de Emacs"
fi
