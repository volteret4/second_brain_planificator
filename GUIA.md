# Guía de uso — Second Brain

## Vista general del sistema

```
Entrada          Registro          Búsqueda           Salida
─────────        ─────────         ─────────           ───────
Hotkey tarea  →  inbox.md      →   fzf / rg        →  Hugo post
Hotkey evento →  tareas.org    →   consult-notes   →  Wallabag
Browser clip  →  Spaces/Wiki   →   db_md_fuzzy     →  CalDAV
Markor móvil  →  Recortes/     →   db_md_consultas →  Taskwarrior
                 journals/
                     ↓
                md_to_org.py ──→ tareas.org ──→ org-caldav ──→ Radicale
                                               Taskwarrior
```

---

## Hotkeys globales (AwesomeWM)

> El daemon de Emacs arranca automáticamente con el sistema (`emacs.service` systemd user).
> Los hotkeys usan `emacsclient -c -n` (no bloquean) y el frame se cierra solo con `C-c C-c` o `C-c C-k`.

| Tecla | Acción |
|---|---|
| `Mod4+Shift+t` | Añadir tarea rápida (rofi → `inbox.md`, sin Emacs) |
| `Mod4+Ctrl+t` | Añadir tarea con org-capture (Emacs) |
| `Mod4+Ctrl+e` | Añadir evento con fecha (org-capture → CalDAV, selector interactivo) |
| `Mod4+Shift+e` | Añadir evento rápido (rofi → `inbox.org`, sin Emacs) |
| `Mod4+n` | Abrir `~/notes/` en Emacs (dired sidebar + GUIA.md) |
| `Mod4+F9` | Buscar en contenido de notas (rg+fzf → emacsclient) |
| `Mod4+Shift+F9` | Buscar por nombre de nota (fd+fzf → emacsclient) |

---

## Emacs — keybindings (`SPC n`)

| Tecla | Acción |
|---|---|
| `SPC n n` | Nueva nota (Denote: pide título + tags) |
| `SPC n f` | Abrir o crear nota por nombre |
| `SPC n s` | Buscar notas por título (consult-notes) |
| `SPC n S` | Buscar en contenido de todas las notas |
| `SPC n g` | Ripgrep en el vault |
| `SPC n i` | Insertar enlace a otra nota |
| `SPC n b` | Ver backlinks de la nota actual |
| `SPC n R` | Recortar selección → nueva nota |
| `SPC n r` | Renombrar nota (actualiza enlaces) |
| `SPC n t` | org-capture (menú de templates) |
| `SPC n a` | org-agenda |
| `SPC n c` | Sync manual con Radicale (org-caldav) |
| `SPC n d` | Insertar fecha `YYYY-MM-DD` |
| `SPC n D` | Insertar timestamp ISO completo |
| `SPC n x` | Abrir `inbox.org` |
| `SPC n j` | Abrir diario (`journals/diario.org`) |
| `SPC n T` | Abrir `tareas.org` |
| `SPC n p` | Toggle preview renderizado de Markdown (en eww) |
| `SPC n m` | Toggle marcadores Markdown visibles/ocultos (`*bold*` ↔ **bold**) |

**En markdown, pegar URL sobre texto seleccionado:**
`gp` (modo normal/visual) → convierte en `[texto seleccionado](url)`

---

## Workspace de notas (Zellij)

```bash
zellij action new-tab --layout notes
# o desde el menú de layouts: Ctrl+o → t → notas
```

Layout:
```
┌──────────────────────────┬──────────────┐
│                          │ consult-notes│
│       Emacs (75%)        ├──────────────┤
│                          │  terminal    │
└──────────────────────────┴──────────────┘
```

---

## Flujo de tareas

### Crear tarea

**Desde nota .md** — cualquier checkbox se sincroniza:
```markdown
- [ ] Revisar configuración de nginx
- [ ] Actualizar script de backup
```
`md_to_org.py` la convierte en `* TODO` en `tareas.org` y en una tarea de Taskwarrior en el siguiente ciclo (cada hora o al apagar).

**Forzar sync inmediato:**
```bash
python3 ~/gits/pollo/second_brain/scripts/sync/md_to_org.py
```

**Directamente en Emacs** (`SPC n t` → `t`):
```
* TODO Revisar configuración de nginx
  CREATED: [2026-06-11]
```

### Completar tarea

- Marcar `[x]` en el `.md` → siguiente sync propaga HECHO a org y done a Taskwarrior
- Marcar HECHO en `tareas.org` → siguiente sync marca `[x]` en el `.md`
- `task UUID done` en terminal → no propaga automáticamente al .md (solo hacia adelante)

### Ver tareas

```bash
task               # pendientes
task +md           # solo las del second brain
task project:wiki  # por proyecto/sección
```

En Emacs: `SPC n a` → org-agenda

---

## Flujo de notas

### Crear nota nueva

```
SPC n n  →  título  →  tags  →  genera:
~/notes/20260611T143022--titulo-de-la-nota__tag1_tag2.md
```

Frontmatter generado automáticamente:
```yaml
---
title: Titulo de la nota
date: 2026-06-11T14:30:22
tags: [tag1, tag2]
identifier: "20260611T143022"
---
```

### Capturar desde el navegador

Script `crear_obs_md.sh` (asignar hotkey en AwesomeWM):
- Lee título y contenido del portapapeles
- Detecta URL del navegador activo
- Pide carpeta destino con rofi
- Crea `~/notes/Spaces/Wiki/{carpeta}/{titulo}.md`

### Tagguear notas existentes

```bash
# Un archivo
python3 scripts/utils/auto_tag.py --file ~/notes/Spaces/Wiki/Linux/docker.md

# Directorio completo
python3 scripts/utils/auto_tag.py --dir ~/notes/Spaces/Wiki/

# Ver qué haría sin modificar
python3 scripts/utils/auto_tag.py --dir ~/notes/ --dry-run
```

---

## Búsqueda

| Método | Contexto | Comando |
|---|---|---|
| fzf + rg (contenido) | terminal / hotkey | `Mod4+F9` o `obsidian-fuzzy.sh` |
| fzf (nombre) | terminal / hotkey | `Mod4+Shift+F9` |
| consult-notes | Emacs | `SPC n s` |
| consult-ripgrep | Emacs | `SPC n S` o `SPC n g` |
| CLI con filtros | terminal | `db_md_consultas.py` |
| GUI PyQt6 | escritorio | `db_md_fuzzy_menu.py` |

```bash
# CLI: buscar por tag y fecha
python3 ~/Scripts/utilities/tiddlywiki/db_md_consultas.py \
    --tags linux docker --since 2026-01-01

# Buscar por tag en nombre de archivo (Denote)
fd __linux ~/notes/
```

---

## Sincronización

### CalDAV (Radicale)
```
tareas.org  ←──org-caldav──→  Radicale (192.168.1.133:5232)
```
- **Manual:** `SPC n c` en Emacs
- **Automático:** vdirsyncer cron cada hora + systemd md-to-org

### Syncthing
- Vault `~/notes/` sincronizado entre PC, pepecono y móvil
- Markor en móvil escribe en `Spaces/Wiki/Markor/`

### SQLite (búsqueda)
```bash
# Reindexar
python3 ~/Scripts/utilities/tiddlywiki/db_md_crear.py \
    --config ~/Scripts/utilities/tiddlywiki/wiki_sync_config.json

# Forzar reindexado completo
python3 ... --force

# Optimizar
python3 ... --optimize
```
Cron automático: cada 30 minutos.

---

## Eventos y calendario

**Modo rápido (sin Emacs):** `Mod4+Shift+e`
1. Rofi pide título del evento
2. Rofi pide fecha `YYYY-MM-DD HH:MM` (prerrellena con hoy)
3. Se añade como `* SCHEDULED` a `inbox.org`
4. En siguiente sync de org-caldav sube a Radicale

**Modo completo (con selector interactivo):** `Mod4+Ctrl+e`
1. Emacs abre org-capture template `e`
2. Emacs pide título y fecha/hora (`%^T` → selector interactivo de calendario)
3. Guardar (`C-c C-c`)
4. `SPC n c` → sube a Radicale vía org-caldav

---

## Publicar en Hugo

```bash
# Script mihitas (rutas ya configuradas)
~/Scripts/menus/mihitas
```

Las notas en `Spaces/Wiki/` y `Spaces/Blogs/` son `.md` planos compatibles directamente con Hugo.

---

## Mantenimiento

```bash
# Estado de los servicios systemd
systemctl --user status md-to-org-hourly.timer
systemctl --user status md-to-org.service

# Logs de sincronización
journalctl --user -u md-to-org-hourly.service -n 50

# Estadísticas del vault
sqlite3 ~/Scripts/utilities/tiddlywiki/wiki_obsidian.db \
    "SELECT COUNT(*) FROM snippets; SELECT COUNT(DISTINCT tag) FROM tags;"

# Tareas en Taskwarrior sin uuid (pendiente de backfill)
python3 scripts/utils/tw_backfill.py --dry-run
```

---

## inbox.org y diario.org

### inbox.org — captura sin clasificar

`~/notes/inbox.org` es el "inbox GTD": todo lo que no sabes dónde poner entra aquí.

Se crea automáticamente la primera vez que usas una plantilla de org-capture.

| Plantilla | Qué crea |
|---|---|
| `t` (SPC n t → t) | `* TODO` en `tareas.org → Inbox` |
| `n` (nota rápida) | entrada en `inbox.org` |
| `l` (link browser) | entrada en `inbox.org` con URL |
| `Mod4+Shift+e` | evento `SCHEDULED` en `inbox.org` |

**Flujo recomendado:** Capturas sin pensar → una vez a la semana abres `SPC n x` y clasificas: mueves entradas a la nota correcta o a `tareas.org`.

### diario.org — journal por fechas

`~/notes/journals/diario.org` usa estructura `file+datetree`: Emacs construye automáticamente un árbol Año → Mes → Día.

Plantilla `j` (SPC n t → j) añade una entrada con timestamp bajo la fecha de hoy.

**Para qué sirve:** log del día, reflexiones, ideas, decisiones. No es obligatorio — si no lo usas no pasa nada. Si lo abres con `SPC n j` y lo ves vacío, es normal: solo crece cuando usas la plantilla `j`.

**Navegar el diario:**
- `TAB` sobre un año/mes: fold/unfold
- `S-TAB`: colapsar todo el árbol

---

## Archivos clave

| Archivo | Propósito |
|---|---|
| `~/notes/tareas.org` | Fuente de verdad de tareas (→ CalDAV) |
| `~/notes/inbox.org` | Captura rápida sin clasificar (revisar periódicamente) |
| `~/notes/Important/inbox.md` | Inbox de checkboxes desde hotkeys (→ Taskwarrior) |
| `~/notes/journals/diario.org` | Diario con árbol año/mes/día |
| `.task_checkpoint.json` | Estado de sincronización md↔org↔TW |
| `config.json` | Config central del sistema |
| `~/.encrypted.env` | Credenciales cifradas (SOPS+AGE) |
