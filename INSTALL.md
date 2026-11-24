# Instalación del Second Brain

## Dependencias

```bash
# Arch / Manjaro
paru -S doom-emacs-git taskwarrior rofi fd ripgrep fzf bat \
        libnotify alacritty python-pip sops age \
        vdirsyncer sqlite python-pyqt6

# Python venv (secretos)
python3 -m venv ~/Scripts/python_venv
pip install -r scripts/sync/requirements.txt   # si existe
```

Doom Emacs (si no está instalado):
```bash
git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
~/.config/emacs/bin/doom install
```

Añadir al `.zshrc`:
```bash
export PATH="$HOME/.config/emacs/bin:$HOME/Scripts/second_brain:$PATH"
```

---

## Secretos (SOPS + AGE)

El sistema usa SOPS con clave AGE para cifrar credenciales.

**1. Generar clave AGE** (si no existe):
```bash
age-keygen -o ~/.age/key.txt
# Apuntar la clave pública que muestra
```

**2. Crear / editar `~/.encrypted.env`**:
```bash
sops ~/.encrypted.env
```

Contenido mínimo:
```bash
RADICALE_URL="http://192.168.1.133:5232"
RADICALE_USER="pollo"
RADICALE_PASSWORD="tu_password"
RADICALE_CALENDAR_ID="uuid-del-calendario-de-tareas"
```

**3. Librería sopsdotenv** (para los scripts Python):
```bash
git clone https://github.com/volteret4/sopsdotenv ~/Scripts/tools/sopsdotenv
```

---

## Instalación

```bash
git clone https://github.com/volteret4/second_brain_planificator ~/gits/pollo/second_brain
cd ~/gits/pollo/second_brain
bash configs/INSTALL.sh
```

El script hace:
- Symlinks de `configs/doom/*.el` → `~/.config/doom/`
- Symlink de `notes-layout.kdl` → `~/.config/zellij/layouts/notes.kdl`
- Copia y activa las unidades systemd (`md-to-org.service`, timer)
- Symlink de `keys_second_brain.lua` → `~/.config/awesome/`
- Symlinks de los scripts de hotkeys → `~/Scripts/second_brain/`
- Crea los archivos `.org` del vault si no existen

---

## Post-instalación

### 1. Sincronizar paquetes de Emacs
```bash
doom sync
```

### 2. Copiar / migrar el vault
```bash
rsync -av --exclude='.obsidian' --exclude='Spaces/Scripts/' \
    /ruta/vault/antiguo/ ~/notes/
```

### 3. Indexar la base de datos SQLite
```bash
python3 ~/Scripts/utilities/tiddlywiki/db_md_crear.py \
    --config ~/Scripts/utilities/tiddlywiki/wiki_sync_config.json
```

### 4. Primer sync CalDAV
Abrir Emacs y ejecutar `SPC n c` (org-caldav-sync).

### 5. AwesomeWM — añadir al `rc.lua`
```lua
local sb = require("keys_second_brain")
globalkeys = awful.util.table.join(globalkeys, sb.keys)
```

Regla floating para la búsqueda (en `awful.rules.rules`):
```lua
{ rule = { class = "sb-search" },
  properties = { floating = true, width = 1200, height = 700,
                 placement = awful.placement.centered } },
```

Reiniciar AwesomeWM: `Mod4+Ctrl+r`

### 6. Cron jobs
```bash
crontab -e
```
Añadir:
```cron
30 * * * *  python3 ~/Scripts/utilities/tiddlywiki/db_md_crear.py --config ~/Scripts/utilities/tiddlywiki/wiki_sync_config.json --optimize --verbose >> ~/.local/share/second_brain/db_md.log 2>&1
10 * * * *  ~/Scripts/utilities/cron/sync_vdir.sh >> ~/.local/share/second_brain/vdir.log 2>&1
```

### 7. Backfill de Taskwarrior (solo en primera instalación con notas existentes)
```bash
python3 scripts/utils/tw_backfill.py
```

---

## Verificación

```bash
# Vault accesible
ls ~/notes/tareas.org

# DB indexada
sqlite3 ~/Scripts/utilities/tiddlywiki/wiki_obsidian.db \
    "SELECT COUNT(*) FROM snippets;"

# Taskwarrior recibe nuevas tareas
echo "- [ ] test instalación" >> ~/notes/Important/inbox.md
python3 ~/gits/pollo/second_brain/scripts/sync/md_to_org.py
task +md | grep "test instalación"

# Emacs arranca sin errores
emacs --batch --load ~/.config/doom/config.el 2>&1 | grep -i error | head -5

# Hotkeys disponibles
ls ~/Scripts/second_brain/
```

---

## Estructura del repositorio

```
second_brain/
├── config.json                    ← rutas, caldav, taskwarrior
├── configs/
│   ├── INSTALL.sh                 ← instalador único
│   ├── awesomewm/keys_second_brain.lua
│   ├── doom/{config,init,packages}.el
│   ├── systemd/{md-to-org.*}
│   └── zellij/notes-layout.kdl
└── scripts/
    ├── hotkeys/                   ← sb_add_task, sb_add_event, sb_search_notes
    ├── sync/                      ← md_to_org, db_md_crear, sync_vdir
    ├── search/                    ← db_md_fuzzy_menu, db_md_consultas
    ├── capture/                   ← crear_obs_md
    └── utils/                     ← auto_tag, tw_backfill
```
