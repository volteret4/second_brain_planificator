#!/usr/bin/env bash
#
# migrate_md_to_org.sh — Convierte notas .md a .org usando pandoc.
# Los originales se mueven a ~/notes/.md_backup/ (no se borran).
#
# Uso:
#   bash migrate_md_to_org.sh          # migración completa
#   bash migrate_md_to_org.sh --dry-run  # solo lista los archivos sin tocar nada
#

VAULT="$HOME/notes"
BACKUP="$VAULT/.md_backup"
DRY_RUN=false

[[ "$1" == "--dry-run" ]] && DRY_RUN=true

if ! command -v pandoc &>/dev/null; then
    echo "ERROR: pandoc no encontrado. Instalar con: sudo pacman -S pandoc"
    exit 1
fi

count=0; errors=0
mkdir -p "$BACKUP"

while IFS= read -r md_file; do
    rel="${md_file#$VAULT/}"
    org_file="${md_file%.md}.org"

    if $DRY_RUN; then
        echo "[dry-run] $rel → ${rel%.md}.org"
        ((count++))
        continue
    fi

    if pandoc -f markdown -t org --wrap=none "$md_file" -o "$org_file" 2>/dev/null; then
        mkdir -p "$BACKUP/$(dirname "$rel")"
        mv "$md_file" "$BACKUP/$rel"
        ((count++))
        echo "✓ $rel"
    else
        ((errors++))
        echo "✗ ERROR: $rel"
    fi
done < <(find "$VAULT" -name "*.md" | sort)

echo ""
echo "Total: $count convertidos, $errors errores"
$DRY_RUN && echo "(dry-run — no se ha modificado nada)"
$DRY_RUN || echo "Originales en: $BACKUP"
