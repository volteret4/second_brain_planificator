;;; config.el -*- lexical-binding: t; -*-

;;; ─── IDENTIDAD ───────────────────────────────────────────────────────────────
(setq user-full-name  "volteret4"
      user-mail-address "viciosmusicales@gmail.com")

;;; ─── APARIENCIA ──────────────────────────────────────────────────────────────
(setq doom-font              (font-spec :family "Mononoki Nerd Font Mono" :size 15)
      doom-theme             'doom-one
      display-line-numbers-type 'relative)

;; Bug conocido de Emacs daemon: frames nuevos (emacsclient -c) no heredan el tema.
(when (daemonp)
  (add-hook 'after-make-frame-functions
            (lambda (frame)
              (when (display-graphic-p frame)
                (with-selected-frame frame
                  (load-theme doom-theme t)
                  (set-frame-font doom-font nil t))))))

;;; ─── SECRETOS VÍA SOPS ───────────────────────────────────────────────────────
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
(setq org-directory my/vault)

(after! org
  (setq
   org-agenda-files (list (concat my/vault "tareas.org")
                          (concat my/vault "proyectos.org"))
   org-default-notes-file (concat my/vault "inbox.org")

   org-todo-keywords
   '((sequence "TODO(t)" "HOY(h)" "ESPERANDO(e@/!)" "|" "HECHO(x!)" "CANCELADO(c@)"))

   org-todo-keyword-faces
   '(("HOY"       . (:foreground "#fab387" :weight bold))
     ("ESPERANDO" . (:foreground "#89b4fa"))
     ("CANCELADO" . (:foreground "#6c7086" :strike-through t)))

   org-log-done       'time
   org-log-into-drawer t
   org-startup-folded  'content
   org-ellipsis        " ▾"
   org-hide-emphasis-markers t
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

;; Cierra el frame flotante de org-capture al confirmar o abortar.
(defun my/org-capture-close-frame (&rest _)
  (when (and (frame-live-p (selected-frame))
             (> (length (frame-list)) 1))
    (delete-frame)))
(add-hook 'org-capture-after-finalize-hook #'my/org-capture-close-frame)

;;; ─── ORG-CALDAV — sync con Radicale ─────────────────────────────────────────
(use-package! org-caldav
  :after org
  :config
  (let* ((base-url (or (my/sops-get "RADICALE_URL")         "http://192.168.1.133:5232"))
         (ruser    (or (my/sops-get "RADICALE_USER")        "pollo"))
         (rpass    (or (my/sops-get "RADICALE_PASSWORD")    ""))
         (cal-id   (or (my/sops-get "RADICALE_CALENDAR_ID") "7c44de6e-69ac-8496-f46d-d6753c9eab1f"))
         (full-url (replace-regexp-in-string
                    "^\\(https?://\\)" (format "\\1%s:%s@" ruser rpass)
                    (format "%s/%s" base-url ruser))))
    (setq org-caldav-url                     full-url
          org-caldav-calendar-id             cal-id
          org-caldav-inbox                   (concat my/vault "tareas.org")
          org-caldav-files                   (list (concat my/vault "tareas.org"))
          org-caldav-sync-changes-to-org     'all
          org-caldav-delete-calendar-entries 'ask)))

;;; ─── DENOTE — gestión de notas .org ─────────────────────────────────────────
(use-package! denote
  :config
  (setq denote-directory         my/vault
        denote-file-type         'org
        denote-prompts           '(title keywords)
        denote-known-keywords
        '("linux" "python" "música" "blog" "tutorial" "snippet"
          "referencia" "proyecto" "caldav" "scripts" "emacs"
          "nix" "alpine" "journal" "inbox")
        denote-rename-buffer-format "[N] %t"
        denote-date-format nil))

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

;;; ─── OX-HUGO — exportar org → Hugo ──────────────────────────────────────────
(use-package! ox-hugo
  :after ox
  :config
  ;; Directorio base de Hugo (ajustar si tienes varios sitios)
  (setq org-hugo-base-dir (expand-file-name "~/gits/pollo/")))

;;; ─── KEYBINDINGS — SPC n = second brain ─────────────────────────────────────
(map! :leader
      (:prefix ("n" . "notas")

       ;; ── Denote ──────────────────────────────────────────────────────────
       "n" #'denote
       "f" #'denote-open-or-create
       "i" #'denote-insert-link
       "b" #'denote-backlinks
       "r" #'denote-rename-file
       "R" #'denote-region

       ;; ── Búsqueda ────────────────────────────────────────────────────────
       "s" #'consult-notes
       "S" #'consult-notes-search-in-all-notes
       "g" #'consult-ripgrep

       ;; ── Org / tareas ────────────────────────────────────────────────────
       "t" #'org-capture
       "a" #'org-agenda
       "c" #'org-caldav-sync

       ;; ── Insertar fecha ───────────────────────────────────────────────────
       "d" (cmd! (insert (format-time-string "%Y-%m-%d")))
       "D" (cmd! (insert (format-time-string "%Y-%m-%dT%H:%M:%S")))

       ;; ── Archivos frecuentes ──────────────────────────────────────────────
       "x" (cmd! (find-file (concat my/vault "inbox.org")))
       "j" (cmd! (find-file (concat my/vault "journals/diario.org")))
       "T" (cmd! (find-file (concat my/vault "tareas.org")))))

;; Pegar URL como link markdown sobre texto seleccionado (gp en normal/visual)
(defun my/paste-as-md-link ()
  "Región activa + URL en portapapeles → [texto](url). Si no, pega normal."
  (interactive)
  (let ((url  (ignore-errors (current-kill 0 t)))
        (text (when (use-region-p)
                (delete-and-extract-region (region-beginning) (region-end)))))
    (cond
     ((and text url (string-match-p "\\`https?://" url))
      (insert (format "[%s](%s)" text url)))
     (text (insert text))
     (t    (yank)))))

(map! :after markdown-mode
      :map markdown-mode-map
      :nv "gp" #'my/paste-as-md-link)

;;; ─── DASHBOARD ───────────────────────────────────────────────────────────────
(setq +doom-dashboard-banner-file
      (expand-file-name "~/gits/pollo/second_brain/ascii.txt"))

(after! doom-dashboard
  (nconc +doom-dashboard-menu-sections
         `(("Nueva nota"
            :icon (nerd-icons-faicon "nf-fa-file-text-o" :face 'doom-dashboard-menu-title)
            :key "SPC n n"
            :action denote)
           ("Buscar en vault"
            :icon (nerd-icons-faicon "nf-fa-search" :face 'doom-dashboard-menu-title)
            :key "SPC n g"
            :action consult-ripgrep)
           ("Inbox"
            :icon (nerd-icons-faicon "nf-fa-inbox" :face 'doom-dashboard-menu-title)
            :key "SPC n x"
            :action ,(cmd! (find-file (concat my/vault "inbox.org"))))
           ("Diario"
            :icon (nerd-icons-faicon "nf-fa-book" :face 'doom-dashboard-menu-title)
            :key "SPC n j"
            :action ,(cmd! (find-file (concat my/vault "journals/diario.org"))))
           ("Tareas"
            :icon (nerd-icons-octicon "nf-oct-checklist" :face 'doom-dashboard-menu-title)
            :key "SPC n T"
            :action ,(cmd! (find-file (concat my/vault "tareas.org")))))))
