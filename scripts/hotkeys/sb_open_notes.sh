#!/usr/bin/env bash
#
# sb_open_notes.sh — Abre frame Emacs y cambia al workspace "notes".
# Crea el workspace la primera vez con SPC TAB n, luego persp-mode lo recuerda.
# Mod4+n en AwesomeWM.
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

_ensure_daemon || { notify-send -i dialog-error "Second Brain" "No se pudo arrancar el daemon de Emacs"; exit 1; }

# Si el workspace "notes" ya existe, cambiar a él tras el timer de persp-mode.
# Si no existe aún: solo abre el frame (crear workspace con SPC TAB n dentro de Emacs).
emacsclient --socket-name="$SOCKET" -c -n \
    -e '(when (+workspace-exists-p "notes") (run-with-timer 0.1 nil (lambda () (+workspace/switch-to "notes"))))'
