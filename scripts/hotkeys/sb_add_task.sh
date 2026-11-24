#!/usr/bin/env bash
#
# sb_add_task.sh — Añadir tarea rápida al second brain desde hotkey AwesomeWM.
#
# Sin args:   rofi → escribe "- [ ] texto" en inbox.md (sin depender de Emacs)
# --emacs:    org-capture template "t" en Emacs via emacsclient (no bloquea)
#

SOCKET="/run/user/$(id -u)/emacs/server"
INBOX="$HOME/notes/Important/inbox.md"

_ensure_daemon() {
    emacsclient --socket-name="$SOCKET" -e 't' &>/dev/null && return 0
    systemctl --user restart emacs.service &>/dev/null
    for i in $(seq 20); do
        sleep 0.5
        emacsclient --socket-name="$SOCKET" -e 't' &>/dev/null && return 0
    done
    return 1
}

if [[ "$1" == "--emacs" ]]; then
    if _ensure_daemon; then
        # -n: no bloquea el hotkey; el frame se cierra solo al C-c C-c / C-c C-k
        emacsclient --socket-name="$SOCKET" -c -n -e '(org-capture nil "t")'
    else
        notify-send -i dialog-error "Second Brain" "No se pudo arrancar el daemon de Emacs"
    fi
    exit 0
fi

task=$(rofi -dmenu -p "Nueva tarea" -lines 0 -width 50 2>/dev/null)
[[ -z "$task" ]] && exit 0

mkdir -p "$(dirname "$INBOX")"
echo "- [ ] $task" >> "$INBOX"
notify-send -i emblem-default -t 3000 "Tarea añadida" "$task"
