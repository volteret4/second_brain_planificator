# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Contexto del proyecto

Repositorio de planificación para migrar un segundo cerebro desde Obsidian hacia herramientas más ligeras. Las notas son archivos Markdown planos, la fuente de verdad vive en el vault de Obsidian montado en `/mnt/windows/FTP/wiki/Obsidian/` (partición Windows).

**Preferencias del usuario:** TUI sobre GUI, sin apps Electron. Editor habitual: helix (vim en servidores). Shell: zsh + zellij. Los scripts deben poder usarse desde otros programas.

---

## Arquitectura del sistema actual

### Pipeline de sincronización (cron)

```
Obsidian vault (/mnt/windows/FTP/wiki/Obsidian/)
    │
    ├── db_md_crear.py     → SQLite DB con FTS5  (búsqueda de notas)
    ├── scripts_to_md.py   → ~/Scripts/ → Obsidian/Spaces/Scripts/ (scripts como snippets MD)
    ├── mfuz_to_md.py      → music-fuzzy/ → Obsidian/Spaces/Blogs/ (igual, para ese proyecto)
    └── sync_vdir.sh       → vdirsyncer → Obsidian/calendars/ (tareas y calendarios CalDAV)
```

### Capa de búsqueda y consulta

| Script | Uso |
|---|---|
| `db_md_fuzzy_menu.py` | GUI PyQt6 (Catppuccin Mocha) para buscar notas en la DB |
| `db_md_async_search.py` | Worker de búsqueda FTS asíncrono para el GUI |
| `db_md_consultas.py` | CLI para consultas con filtros de fecha y tags |
| `crear_obs_md.sh` | Crea notas desde el portapapeles del navegador activo |

---

## Rutas clave

| Recurso | Ruta |
|---|---|
| Vault Obsidian | `/mnt/windows/FTP/wiki/Obsidian/` |
| Scripts de sync/search | `/home/huan/Scripts/utilities/tiddlywiki/` |
| Scripts de cron | `/home/huan/Scripts/utilities/cron/` |
| SQLite DB | `/home/huan/Scripts/utilities/tiddlywiki/wiki_obsidian.db` |
| Config sync | `/home/huan/Scripts/utilities/tiddlywiki/wiki_sync_config.json` |
| Config DB | `/home/huan/Scripts/utilities/tiddlywiki/db_md_config.json` |
| Proyectos varios | `/home/huan/gits/pollo/` |
| Scripts con hotkey | `/home/huan/Scripts/` |

---

## SQLite DB (`wiki_obsidian.db`)

Tablas: `snippets` (id, filename, path, directory, content, source, last_modified, file_hash), `tags`, `snippet_tags` (relación N:M), `sync_metadata`, `snippet_fts` (virtual FTS5).

La tabla FTS5 indexa: filename, content, path, directory, source. Se reconstruye automáticamente si el conteo difiere de `snippets`.

---

## Scripts de sincronización

### `db_md_crear.py`
Sincroniza el vault Obsidian → SQLite. Extrae tags desde YAML frontmatter (formatos: lista, inline, multilínea) y hashtags inline. Detecta archivos borrados y los elimina de la DB. Ejecutar:
```bash
python3 /home/huan/Scripts/utilities/tiddlywiki/db_md_crear.py --config wiki_sync_config.json
python3 /home/huan/Scripts/utilities/tiddlywiki/db_md_crear.py --force    # fuerza actualización de todo
python3 /home/huan/Scripts/utilities/tiddlywiki/db_md_crear.py --optimize # optimiza la DB
```

### `scripts_to_md.py` / `mfuz_to_md.py`
Convierten scripts a archivos `.md` con bloques de código fenced. Wrappean el contenido como ` ```lang\n{content}\n``` `. Extraen TODOs (`# TODO:`) y los añaden a `Obsidian/Important/Tareas.md` con fechas caldav.

### `db_md_fuzzy_menu.py`
Requiere PyQt6, markdown, `db_md_async_search`. Busca en FTS5 con filtro opcional por carpetas. Tema Catppuccin Mocha hardcodeado.

---

## Estructura del vault Obsidian

```
Obsidian/
├── Spaces/
│   ├── Wiki/          ← notas del segundo cerebro (algunas → posts hugo)
│   │   └── Markor/    ← notas desde móvil
│   ├── Blogs/         ← contenido para webs hugo
│   ├── Linux/         ← notas Linux, alpine, nix, comandos, tutoriales
│   └── Scripts/       ← scripts sincronizados por scripts_to_md.py
├── Projects/          ← gestión de tareas (integración caldav + taskwarrior)
├── Important/         ← Tareas.md (destino de TODOs extraídos)
├── Journals/          ← diario con archivos del día
├── plantillas/        ← plantillas Obsidian
├── calendars/         ← sincronizado desde vdirsyncer/radicale
└── Adjuntos/          ← imágenes y archivos visuales
```

---

## Ecosistema relacionado

**Fuentes de conocimiento:** FreshRSS, Wallabag, Audiobookshelf, Airsonic  
**Publicación:** Hugo (webs mihitas/notas) via `/home/huan/Scripts/menus/mihitas`  
**Tareas/calendario:** Radicale (CalDAV, fuente de verdad) → vdirsyncer → Obsidian  
**Música:** music-fuzzy (`/home/huan/gits/pollo/music-fuzzy`) — PyQt app con DB propia de MB/lastfm/discogs

**Bots Telegram relevantes:**
- `/home/huan/gits/pollo/bot_conciertos` — buscador Ticketmaster
- `/home/huan/gits/pollo/bot_infomusic` — info musical

**Proyectos incompletos con potencial de integración:**
- `/home/huan/gits/pollo/ensayos-musicales` — enciclopedia musical desde podcasts
- `/home/huan/gits/pollo/mix_rater` — valoración de canciones para recomendador
