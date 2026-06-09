# Plan: Second Brain — Diseño del sistema

## Contexto

El usuario quiere migrar de Obsidian a un sistema más ligero, scriptable y TUI-first, manteniendo archivos .md planos compatibles con rg, fzf, Markor, Hugo y sus scripts existentes. Ha descartado Electron. Tiene infraestructura de servidor significativa, ama los hotkeys/QoL, usa Syncthing para sync, y quiere Emacs con evil-mode dentro de un workspace de Zellij dedicado.

Perfil de uso extraído del test:
- Captura: impulso inmediato (necesita hotkey global rápida)
- Búsqueda: rg/fzf, quiere mejorar tags y enlaces vía scripts
- Contenido: todo tipo (snippets, tutoriales, referencias, ideas/reflexiones)
- Revisión: ocasional, no hay rutina rígida
- Móvil: secundario (Markor + Syncthing ya funciona)
- Salida: nota = post Hugo (sin transformación intermedia)
- Editor: Emacs + evil-mode + Zellij

---

## PUNTO 1 — Herramienta de control de .md

### Recomendación: Doom Emacs + Denote + evil-mode

**Por qué Denote y no Org-roam:**
- Los ficheros siguen siendo .md planos → Syncthing, Markor, Hugo, rg, scripts existentes no cambian nada
- Tags en el nombre del fichero: `20241209T143000--titulo-nota__linux_tutorial.md`
  - Buscar tags = `fd __linux` en terminal. Sin DB. Sin YAML obligatorio.
- Sin base de datos externa (Org-roam requiere SQLite propio)
- Backlinks básicos: Denote puede insertar y resolver `[[denote:ID]]` links
- Los QoL que pide son todos implementables con Elisp simple o ya existen:
  - Insertar fecha → `C-c .` (built-in Emacs) o en nombre al crear nota
  - Recortar región a nueva nota → `denote-region` (función incluida en Denote)
  - Insertar enlace al pegar URL sobre texto seleccionado → función Elisp de ~10 líneas

**Por qué Doom Emacs y no vanilla:**
- evil-mode + consult + vertico + orderless ya vienen preconfigurados y bien integrados
- Mucho menos tiempo de configuración inicial (~30 min vs días)
- Igual de extensible que vanilla: todo es Elisp, todo es configurable
- Comunidad grande, documentación clara

**PROS de Emacs+Denote para este caso:**
| Pros | Detalle |
|---|---|
| Captura rápida global | `org-capture` con hotkey → inbox.md desde cualquier app |
| QoL nativo extensible | Insertar fecha, recortar a nota, auto-enlace al pegar URL → Elisp |
| evil-mode | Mismos keybindings modales que helix. No hay que reaprender edición. |
| consult-notes + rg | Búsqueda fuzzy sobre contenido y nombre de nota integrada en el editor |
| emacsclient | Daemon en background → arranque instantáneo (< 0.1s) |
| Zellij layout | Un workspace dedicado: panel editor + panel dired + panel terminal |
| Tramp | Editar notas en servers remotos desde el mismo Emacs |
| .md planos | Syncthing, Markor, Hugo, scripts Python/bash → todo sigue igual |
| denote-region | Recortar selección a nueva nota → ya existe en Denote |

**CONTRAS:**
| Contras | Mitigación |
|---|---|
| Curva de config Emacs (Elisp) | Doom Emacs reduce esto enormemente. La config de Denote son ~20 líneas. |
| Algunos atajos de Emacs inevitables | Se aprenden en una semana de uso real. evil-mode cubre el 90%. |
| Config puede crecer | Mantener un `config.el` mínimo y disciplinado. No instalar plugins sin propósito. |
| Si el daemon falla, arranque lento | Cron/systemd user service para levantar el daemon al login. |

**Complemento server-side (opcional, recomendado):** SilverBullet en Docker
- Lee los mismos .md del vault (Syncthing llega al server)
- Interfaz web para acceso desde móvil (mejor que solo Markor)
- Sin modificar el vault ni los archivos

---

## PUNTO 2 — Sistema Entrada / Registro / Búsqueda / Salida

### ENTRADA

| Canal | Herramienta | Destino |
|---|---|---|
| Hotkey escritorio | `org-capture` en Emacs (daemon) | `inbox.md` en vault |
| Móvil | Markor + Syncthing | Carpeta `inbox/` en vault |
| Browser → nota | `crear_obs_md.sh` (adaptado, ruta vault) | Carpeta según tag seleccionado |
| Scripts automáticos | `scripts_to_md.py`, `mfuz_to_md.py` (rutas actualizadas) | `Spaces/Scripts/`, `Spaces/Blogs/` |
| CalDAV/tareas | `sync_vdir.sh` (sin cambios) | `calendars/` |

El `inbox.md` o carpeta `inbox/` es el buffer de entrada sin procesar. Se procesa periódicamente (ocasional, sin rutina rígida = perfecto para el perfil del usuario).

### REGISTRO

- **Crear nota nueva** → `M-x denote` en Emacs: pide título + tags → genera `FECHA--titulo__tags.md` automáticamente
- **Journal diario** → mejorar script existente: nota `FECHA--journal.md` con template (tareas del día, archivos modificados, eventos CalDAV del día)
- **Formato de nombre**: `20241209T143022--titulo-de-la-nota__tag1_tag2.md`
  - No es obligatorio migrar todo a este formato de golpe. Las notas nuevas usan Denote, las viejas se migran gradualmente o nunca.

### BÚSQUEDA

| Contexto | Herramienta | Cómo |
|---|---|---|
| Dentro de Emacs | `consult-notes` + `consult-ripgrep` | Fuzzy sobre título y contenido, con preview |
| Terminal / fuera de Emacs | `rg` + `fzf` (igual que ahora) | Sin cambios |
| Búsqueda avanzada (tags, fechas) | `db_md_consultas.py` (actualizar ruta vault) | CLI con filtros |
| GUI fuera de Emacs | `db_md_fuzzy_menu.py` (actualizar ruta vault) | PyQt6, sin cambios de fondo |
| Tags | `fd __tagname` en terminal | Busca archivos por tag en nombre |

La DB SQLite (`db_md_crear.py`) sigue siendo válida. Actualizar `wiki_sync_config.json` con la nueva ruta del vault.

**Mejorar tags vía IA (uso puntual):** script que lea el contenido de una nota y proponga tags usando Claude API → el usuario acepta/rechaza → añade al nombre del fichero. Se ejecuta manualmente, no en cron.

### SALIDA

| Salida | Herramienta | Cambios |
|---|---|---|
| Posts Hugo | Script `mihitas` (sin cambios, .md siguen siendo iguales) | Ninguno |
| Web self-hosted | SilverBullet (Docker, server) | Nuevo, opcional |
| Búsqueda/consulta | db_md_fuzzy_menu.py, db_md_consultas.py | Solo actualizar ruta vault |

---

## PUNTO 3 — Reestructuración de datos

### Estrategia: migración gradual, no big bang

**Fase 0 (preparación):**
1. Mover vault de `/mnt/windows/FTP/wiki/Obsidian/` → `~/notes/` (o `~/vault/`)
2. Añadir `~/notes/` a Syncthing en todos los dispositivos
3. Actualizar rutas en todos los scripts/configs (`wiki_sync_config.json`, `db_md_config.json`, `scripts_to_md.py`, etc.)

**Fase 1 (estructura):**
- Mantener estructura de carpetas actual (Spaces/, Journals/, etc.) — está bien
- Añadir carpeta `inbox/` como buffer de entrada
- Renombrar `calendars/` → puede mantenerse igual
- Eliminar carpeta `Excalidraw/Dibujos/` si no hay visor CLI (o mover adjuntos a `assets/`)

**Fase 2 (tags — mejora gradual):**
- Script Python que analiza frontmatter YAML existente → lista de tags únicos → detecta duplicados/sinónimos → propone consolidación
- Script para añadir tags al nombre del fichero (formato Denote) en notas nuevas
- No forzar renombrado masivo de notas antiguas (riesgo de rotura de links en Hugo, aunque esten en otro servidor los posts de hugo, sincronizan por nombre)

**Fase 3 (enlaces — opcional):**
- Script que detecta menciones de nombres de notas en el contenido → propone insertar `[[denote:ID]]`
- Útil para notas técnicas (Linux, tutoriales) donde ya se referencian entre sí

---

## Verificación

1. **Emacs + Denote funciona**: crear nota con `M-x denote`, verificar nombre generado, abrir desde consult-notes, editar con evil keybindings
2. **org-capture hotkey global**: configurar en `~/.config/doom/config.el`, verificar que funciona desde fuera de Emacs con el daemon activo
3. **rg/fzf sigue funcionando**: buscar texto en notas desde terminal, verificar que las rutas son correctas
4. **Scripts existentes**: ejecutar `db_md_crear.py` con config actualizada, verificar que indexa el nuevo vault
5. **Syncthing**: crear nota en PC, verificar que aparece en móvil (Markor) en < 1 min
6. **Hugo**: publicar una nota existente con script `mihitas`, verificar que el output es correcto
7. **SilverBullet** (si se instala): acceder desde móvil via browser, verificar que lee las notas

---

## Orden de implementación sugerido
0. Copia del vault a `~/notas/` progresivamente. Claude leera las notas, mejorará tags y enlaces a otras notas y finalmente copiará adecuadamente al nuevo vault.
1. Instalar Doom Emacs + configurar evil + Denote (una tarde)
2. Configurar atajos y mostrar cheatshet personalizado para ir aprendiendo
3. Configurar org-capture con hotkey global (daemon systemd)
4. Configurar Zellij layout dedicado para notas
5. Adaptar `crear_obs_md.sh` a la nueva ruta
6. Actualizar `wiki_sync_config.json` + verificar DB SQLite y scripts de búsqueda
7. Script de consolidación de tags (cuando lo anterior esté estable)
8. SilverBullet en Docker en pepecono(último, una vez el flujo desktop esté rodado)
10. Mover vault a `~/notes/` + actualizar Syncthing + actualizar configs de scripts
