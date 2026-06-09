#!/usr/bin/env bash
# Instala los servicios systemd de usuario para md_to_org.py
# Ejecutar una sola vez: bash configs/systemd/INSTALL.sh

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$SYSTEMD_USER_DIR"

# Copiar unidades
cp "$SCRIPT_DIR/md-to-org.service"        "$SYSTEMD_USER_DIR/"
cp "$SCRIPT_DIR/md-to-org-hourly.service" "$SYSTEMD_USER_DIR/"
cp "$SCRIPT_DIR/md-to-org-hourly.timer"   "$SYSTEMD_USER_DIR/"

# Recargar y activar
systemctl --user daemon-reload
systemctl --user enable --now md-to-org.service
systemctl --user enable --now md-to-org-hourly.timer

echo "Servicios instalados:"
systemctl --user status md-to-org.service --no-pager
systemctl --user status md-to-org-hourly.timer --no-pager
