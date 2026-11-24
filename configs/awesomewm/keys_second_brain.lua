-- keys_second_brain.lua
-- Hotkeys del second brain para AwesomeWM.
--
-- Uso: en tu rc.lua añade:
--   local sb = require("keys_second_brain")
--   -- y en la tabla globalkeys:
--   awful.key.join(globalkeys, sb.keys)
--
-- O simplemente copia los awful.key(...) dentro de tu globalkeys existente.

local awful = require("awful")

local SB = os.getenv("HOME") .. "/Scripts/second_brain/"

local keys = awful.util.table.join(

    -- ── Añadir tarea rápida ───────────────────────────────────────────────────
    -- rofi → escribe - [ ] en inbox.md → md_to_org lo sincroniza
    awful.key({ "Mod4", "Shift" }, "t",
        function() awful.spawn(SB .. "sb_add_task.sh") end,
        { description = "añadir tarea (inbox.md)", group = "second brain" }),

    -- Con Ctrl: abre org-capture directamente en Emacs
    awful.key({ "Mod4", "Control" }, "t",
        function() awful.spawn(SB .. "sb_add_task.sh --emacs") end,
        { description = "añadir tarea (org-capture)", group = "second brain" }),

    -- ── Añadir evento al calendario ───────────────────────────────────────────
    -- Con Control: org-capture en Emacs (selector de fecha interactivo → CalDAV)
    awful.key({ "Mod4", "Control" }, "e",
        function() awful.spawn(SB .. "sb_add_event.sh") end,
        { description = "añadir evento (org-capture)", group = "second brain" }),

    -- Con Shift: rofi directo → inbox.org (sin abrir Emacs)
    awful.key({ "Mod4", "Shift" }, "e",
        function() awful.spawn(SB .. "sb_add_event_rofi.sh") end,
        { description = "añadir evento rápido (rofi)", group = "second brain" }),

    -- ── Abrir notes en Emacs ──────────────────────────────────────────────────
    -- Dired sidebar izquierdo (~/notes/) + GUIA.md en panel principal
    awful.key({ "Mod4" }, "n",
        function() awful.spawn(SB .. "sb_open_notes.sh") end,
        { description = "abrir ~/notes en Emacs", group = "second brain" }),

    -- ── Buscar y abrir nota ───────────────────────────────────────────────────
    -- Terminal flotante con rg + fzf, abre en emacsclient
    awful.key({ "Mod4" }, "F9",
        function() awful.spawn(SB .. "sb_search_notes.sh") end,
        { description = "buscar nota (contenido)", group = "second brain" }),

    -- Buscar solo por nombre de archivo
    awful.key({ "Mod4", "Shift" }, "F9",
        function() awful.spawn(SB .. "sb_search_notes.sh --files") end,
        { description = "buscar nota (nombre)", group = "second brain" })
)

return { keys = keys }

-- ── Regla floating para la terminal de búsqueda ──────────────────────────────
-- Añadir en la sección awful.rules.rules de rc.lua:
--
-- {
--     rule = { class = "sb-search" },
--     properties = {
--         floating   = true,
--         width      = 1200,
--         height     = 700,
--         placement  = awful.placement.centered,
--     }
-- },
