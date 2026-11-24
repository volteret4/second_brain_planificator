#!/usr/bin/env bash
#
# sb_add_event_rofi.sh — Añadir evento rápido con rofi → inbox.org (sin Emacs).
# Mod4+Shift+e en AwesomeWM.
# Para evento con selector de fecha interactivo en Emacs usa Mod4+Ctrl+e.
#

SOCKET="/run/user/$(id -u)/emacs/server"
INBOX="$HOME/notes/inbox.org"

title=$(rofi -dmenu -p "Evento" -lines 0 -width 50 2>/dev/null)
[[ -z "$title" ]] && exit 0

# Sugerir la fecha de hoy + hora redonda como punto de partida
default_fecha="$(date +%Y-%m-%d) 10:00"
fecha=$(printf '%s' "$default_fecha" | rofi -dmenu -p "Fecha (YYYY-MM-DD HH:MM)" -lines 0 -width 50 2>/dev/null)
[[ -z "$fecha" ]] && exit 0

# Convertir a timestamp org: <2026-06-15 Mon 10:00>
day_of_week=$(date -d "$fecha" "+%a" 2>/dev/null)
if [[ -n "$day_of_week" ]]; then
    ts="<${fecha} ${day_of_week}>"
else
    ts="<${fecha}>"
fi

mkdir -p "$(dirname "$INBOX")"
printf '\n* %s\n  SCHEDULED: %s\n  :PROPERTIES:\n  :CREATED:  [%s]\n  :END:\n' \
    "$title" "$ts" "$(date '+%Y-%m-%d %a %H:%M')" >> "$INBOX"

notify-send -i emblem-default -t 3000 "Evento añadido" "$title — $ts"
