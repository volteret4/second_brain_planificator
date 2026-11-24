#!/usr/bin/env bash
# INSTALL.sh — Instala todos los componentes del second brain.
# Ejecutar desde la raíz del repo: bash configs/INSTALL.sh
#
# Componentes:
#   - Doom Emacs config  → ~/.config/doom/  (symlinks)
#   - Zellij layout      → ~/.config/zellij/layouts/notes.kdl
#   - systemd units      → ~/.config/systemd/user/
#   - AwesomeWM module   → ~/.config/awesome/keys_second_brain.lua
#   - Hotkey scripts     → ~/Scripts/second_brain/

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ok()   { echo "[OK]  $*"; }
skip() { echo "[--]  $* (ya existe)"; }
info() { echo "      $*"; }

# ── 1. Doom Emacs ─────────────────────────────────────────────────────────────
echo ""
echo "=== Doom Emacs ==="
mkdir -p "$HOME/.config/doom"
for f in config.el packages.el init.el; do
    src="$REPO/configs/doom/$f"
    dst="$HOME/.config/doom/$f"
    if [[ ! -f "$src" ]]; then
        info "no encontrado: $src, omitido"
        continue
    fi
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        cp "$dst" "${dst}.bak"
        info "backup: ${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    ok "$f → $dst"
done
info "Recuerda ejecutar: doom sync"

# ── 2. Zellij layout ──────────────────────────────────────────────────────────
echo ""
echo "=== Zellij ==="
mkdir -p "$HOME/.config/zellij/layouts"
src="$REPO/configs/zellij/notes-layout.kdl"
dst="$HOME/.config/zellij/layouts/notes.kdl"
if [[ -f "$src" ]]; then
    ln -sf "$src" "$dst"
    ok "notes.kdl → $dst"
fi

# ── 3. systemd user services ──────────────────────────────────────────────────
echo ""
echo "=== systemd ==="
SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_DIR"
for unit in md-to-org.service md-to-org-hourly.service md-to-org-hourly.timer; do
    src="$REPO/configs/systemd/$unit"
    if [[ -f "$src" ]]; then
        cp "$src" "$SYSTEMD_DIR/"
        ok "$unit"
    fi
done
systemctl --user daemon-reload
systemctl --user enable --now md-to-org.service
systemctl --user enable --now md-to-org-hourly.timer
ok "md-to-org activado"

# Emacs daemon — necesario para los hotkeys (emacsclient -c -n)
if systemctl --user enable --now emacs.service 2>/dev/null; then
    ok "emacs.service activado (daemon siempre disponible para hotkeys)"
else
    info "emacs.service no encontrado en el sistema — instala emacs y vuelve a correr"
fi

# ── 4. AwesomeWM ──────────────────────────────────────────────────────────────
echo ""
echo "=== AwesomeWM ==="
AWESOME_DIR="$HOME/.config/awesome"
src="$REPO/configs/awesomewm/keys_second_brain.lua"
if [[ -d "$AWESOME_DIR" && -f "$src" ]]; then
    ln -sf "$src" "$AWESOME_DIR/keys_second_brain.lua"
    ok "keys_second_brain.lua → $AWESOME_DIR/"
    info "Añade a tu rc.lua:"
    info "  local sb = require('keys_second_brain')"
    info "  globalkeys = awful.util.table.join(globalkeys, sb.keys)"
    info "Y en awful.rules.rules:"
    info "  { rule = { class = 'sb-search' },"
    info "    properties = { floating=true, width=1200, height=700,"
    info "                   placement=awful.placement.centered } },"
else
    skip "AwesomeWM config dir no encontrado o lua ausente"
fi

# ── 5. Hotkey scripts ─────────────────────────────────────────────────────────
echo ""
echo "=== Hotkey scripts ==="
SCRIPTS_DIR="$HOME/Scripts/second_brain"
mkdir -p "$SCRIPTS_DIR"
for script in "$REPO"/scripts/hotkeys/*.sh; do
    name="$(basename "$script")"
    dst="$SCRIPTS_DIR/$name"
    ln -sf "$script" "$dst"
    chmod +x "$script"
    ok "$name → $dst"
done

# ── 6. Directorios del vault ───────────────────────────────────────────────────
echo ""
echo "=== Vault ==="
VAULT="$HOME/notes"
for d in Important journals; do
    mkdir -p "$VAULT/$d"
done
for f in tareas.org proyectos.org inbox.org; do
    if [[ ! -f "$VAULT/$f" ]]; then
        title="${f%.org}"
        printf "#+TITLE: %s\n#+FILETAGS: :%s:\n\n* Inbox\n" "$title" "$title" > "$VAULT/$f"
        ok "creado $VAULT/$f"
    else
        skip "$VAULT/$f"
    fi
done
if [[ ! -f "$VAULT/journals/diario.org" ]]; then
    printf "#+TITLE: Diario\n#+FILETAGS: :diario:\n\n" > "$VAULT/journals/diario.org"
    ok "creado journals/diario.org"
else
    skip "journals/diario.org"
fi

echo ""
echo "=== Instalación completa ==="
echo "Hotkeys disponibles (configura las teclas en rc.lua):"
echo "  Mod4+Shift+t   → añadir tarea (rofi → inbox.md)"
echo "  Mod4+Ctrl+t    → añadir tarea (org-capture en Emacs)"
echo "  Mod4+Shift+e   → añadir evento (org-capture en Emacs)"
echo "  Mod4+F9        → buscar nota (rg+fzf → emacsclient)"
echo "  Mod4+Shift+F9  → buscar nota por nombre"
