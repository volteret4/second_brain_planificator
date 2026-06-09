;;; config.el -*- lexical-binding: t; -*-

;;; ─── IDENTIDAD ───────────────────────────────────────────────────────────────
(setq user-full-name  "volteret4"
      user-mail-address "viciosmusicales@gmail.com")

;;; ─── APARIENCIA ──────────────────────────────────────────────────────────────
(setq doom-font              (font-spec :family "Mononoki Nerd Font Mono" :size 15)
      doom-theme             'doom-one
      display-line-numbers-type 'relative)

;;; ─── SECRETOS VÍA SOPS ───────────────────────────────────────────────────────
;; Lee una KEY de ~/.encrypted.env descifrado con sops+age.
;; Requiere que `sops` esté en PATH y que la clave AGE esté disponible.
(defun my/sops-get (key)
  "Devuelve el valor de KEY desde ~/.encrypted.env (SOPS+age). Nil si no existe."
  (let ((env-file (expand-file-name "~/.encrypted.env")))
    (when (file-exists-p env-file)
      (let ((out (shell-command-to-string
                  (format "sops --decrypt %s 2>/dev/null" env-file))))
        (when (string-match
               (format "^%s=['\"]?\\([^'\"\n]+\\)['\"]?$" (regexp-quote key))
               out)
          (string-trim (match-string 1 out)))))))

;;; ─── RUTAS DEL VAULT ─────────────────────────────────────────────────────────
(defvar my/vault (expand-file-name "~/notes/")
  "Ruta raíz del vault de notas.")

;;; ─── ORG — configuración base ────────────────────────────────────────────────
(setq org-directory my/vault)   ; debe estar antes de que cargue org

(after! org
  (setq
   ;; Archivos que org-agenda escanea
   org-agenda-files (list (concat my/vault "tareas.org")
                          (concat my/vault "proyectos.org"))

   org-default-notes-file (concat my/vault "inbox.org")

   ;; Estados de tarea
   org-todo-keywords
   '((sequence "TODO(t)" "HOY(h)" "ESPERANDO(e@/!)" "|" "HECHO(x!)" "CANCELADO(c@)"))

   org-todo-keyword-faces
   '(("HOY"       . (:foreground "#fab387" :weight bold))
     ("ESPERANDO" . (:foreground "#89b4fa"))
     ("CANCELADO" . (:foreground "#6c7086" :strike-through t)))

   ;; Logging
   org-log-done       'time
   org-log-into-drawer t

   ;; Vista
   org-startup-folded  'content
   org-ellipsis        " ▾"
   org-hide-emphasis-markers t

   ;; Prioridades A-C
   org-priority-highest ?A
   org-priority-lowest  ?C
   org-priority-default ?B))

;;; ─── ORG-CAPTURE — plantillas ────────────────────────────────────────────────
(after! org
  (setq org-capture-templates
    `(("t" "Tarea" entry
       (file+headline ,(concat my/vault "tareas.org") "Inbox")
       "* TODO %?\n  CREATED: %U\n  %i\n  %a"
       :empty-lines 1)

      ("h" "Tarea para hoy" entry
       (file+headline ,(concat my/vault "tareas.org") "Hoy")
       "* HOY %?\n  DEADLINE: %t\n  CREATED: %U"
       :empty-lines 1)

      ("p" "Proyecto" entry
       (file+headline ,(concat my/vault "proyectos.org") "Proyectos")
       "* TODO %?\n  CREATED: %U\n  [/]\n** TODO Definir alcance\n** TODO Primera tarea"
       :empty-lines 1)

      ("n" "Nota rápida → inbox" entry
       (file ,(concat my/vault "inbox.org"))
       "* %?\n  CREATED: %U\n  %i"
       :empty-lines 1)

      ("l" "Link desde browser" entry
       (file ,(concat my/vault "inbox.org"))
       "* %?\n  URL: %x\n  CREATED: %U"
       :empty-lines 1)

      ("e" "Evento" entry
       (file+headline ,(concat my/vault "tareas.org") "Inbox")
       "* %?\n  SCHEDULED: %^T\n  CREATED: %U"
       :empty-lines 1)

      ("j" "Journal" entry
       (file+datetree ,(concat my/vault "journals/diario.org"))
       "* %U %?\n  %i"
       :tree-type week
       :empty-lines 1))))

;;; ─── ORG-CALDAV — sync con Radicale ─────────────────────────────────────────
;; Todos los credenciales se leen de ~/.encrypted.env via SOPS.
;; Añadir al env: RADICALE_URL, RADICALE_USER, RADICALE_PASSWORD, RADICALE_CALENDAR_ID
(use-package! org-caldav
  :after org
  :config
  (let* ((base-url    (or (my/sops-get "RADICALE_URL")         "http://192.168.1.133:5232"))
         (ruser       (or (my/sops-get "RADICALE_USER")        "pollo"))
         (rpass       (or (my/sops-get "RADICALE_PASSWORD")    ""))
         (cal-id      (or (my/sops-get "RADICALE_CALENDAR_ID") "7c44de6e-69ac-8496-f46d-d6753c9eab1f"))
         ;; http://host:port  →  http://user:pass@host:port/user
         (full-url    (replace-regexp-in-string
                       "^\\(https?://\\)" (format "\\1%s:%s@" ruser rpass)
                       (format "%s/%s" base-url ruser))))
    (setq
     org-caldav-url                     full-url
     org-caldav-calendar-id             cal-id
     org-caldav-inbox                   (concat my/vault "tareas.org")
     org-caldav-files                   (list (concat my/vault "tareas.org"))
     org-caldav-sync-changes-to-org     'all
     org-caldav-delete-calendar-entries 'ask)))

;;; ─── DENOTE — gestión de notas .md ──────────────────────────────────────────
(use-package! denote
  :config
  (setq denote-directory         my/vault
        denote-file-type         'markdown-yaml   ; ficheros .md con YAML frontmatter
        denote-prompts           '(title keywords)
        denote-known-keywords
        '("linux" "python" "música" "blog" "tutorial" "snippet"
          "referencia" "proyecto" "caldav" "scripts" "emacs"
          "nix" "alpine" "journal" "inbox")
        denote-rename-buffer-format "[N] %t"
        denote-date-format nil))         ; timestamp ISO estándar

;;; ─── CONSULT-NOTES — búsqueda fuzzy de notas ─────────────────────────────────
(use-package! consult-notes
  :after (consult denote)
  :config
  (setq consult-notes-file-dir-sources
        `(("Wiki"    ?w ,(concat my/vault "Spaces/Wiki/"))
          ("Blog"    ?b ,(concat my/vault "Spaces/Blogs/"))
          ("Linux"   ?l ,(concat my/vault "Spaces/Linux/"))
          ("Inbox"   ?i ,(concat my/vault "inbox/"))
          ("Recortes" ?r ,(concat my/vault "Recortes/"))))
  (consult-notes-denote-mode))

;;; ─── MARKDOWN ────────────────────────────────────────────────────────────────
(after! markdown-mode
  (setq markdown-enable-wiki-links              t
        markdown-wiki-link-search-subdirectories t
        markdown-fontify-code-blocks-natively    t))

;;; ─── QoL: URL → LINK MARKDOWN AL PEGAR SOBRE SELECCIÓN ───────────────────────
(defun my/paste-as-md-link ()
  "Si el portapapeles es una URL y hay región activa → [texto](url).
   Si no hay región, pega normal."
  (interactive)
  (let ((url  (ignore-errors (current-kill 0 t)))
        (text (when (use-region-p)
                (delete-and-extract-region (region-beginning) (region-end)))))
    (cond
     ((and text url (string-match-p "\\`https?://" url))
      (insert (format "[%s](%s)" text url)))
     (text   (insert text))
     (t      (yank)))))

;;; ─── QoL: RECORTAR SELECCIÓN A NUEVA NOTA DENOTE ────────────────────────────
;; `denote-region' ya viene en Denote — se asigna al keymap más abajo.

;;; ─── KEYBINDINGS — SPC n = second brain ─────────────────────────────────────
(map! :leader
      (:prefix ("n" . "notas")

       ;; ── Denote ──────────────────────────────────────────────────────────
       "n" #'denote                    ; nueva nota
       "f" #'denote-open-or-create     ; abrir o crear
       "i" #'denote-insert-link        ; insertar enlace a otra nota
       "b" #'denote-backlinks          ; notas que enlazan esta
       "r" #'denote-rename-file        ; renombrar (actualiza links)
       "R" #'denote-region             ; recortar selección → nueva nota

       ;; ── Búsqueda ────────────────────────────────────────────────────────
       "s" #'consult-notes             ; fuzzy sobre títulos de notas
       "S" #'consult-notes-search-in-all-notes  ; fuzzy sobre contenido
       "g" #'consult-ripgrep           ; ripgrep en el vault

       ;; ── Org / tareas ────────────────────────────────────────────────────
       "t" #'org-capture               ; captura rápida (elige template)
       "a" #'org-agenda                ; agenda
       "c" #'org-caldav-sync           ; sync manual con Radicale

       ;; ── Insertar fecha ───────────────────────────────────────────────────
       "d" (cmd! (insert (format-time-string "%Y-%m-%d")))
       "D" (cmd! (insert (format-time-string "%Y-%m-%dT%H:%M:%S")))

       ;; ── Archivos frecuentes ──────────────────────────────────────────────
       "x" (cmd! (find-file (concat my/vault "inbox.org")))
       "j" (cmd! (find-file (concat my/vault "journals/diario.org")))
       "T" (cmd! (find-file (concat my/vault "tareas.org")))))

;; URL-link al pegar — activo en markdown
(map! :after markdown-mode
      :map markdown-mode-map
      :nv "gp" #'my/paste-as-md-link)
