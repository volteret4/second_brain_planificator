;;; init.el -*- lexical-binding: t; -*-
;; Tras editar, ejecutar: doom sync

(doom! :input
       ;;layout

       :completion
       (corfu +orderless)
       vertico

       :ui
       doom
       dashboard
       hl-todo
       modeline
       neotree
       ophints
       (popup +defaults)
       (vc-gutter +pretty)
       vi-tilde-fringe
       workspaces

       :editor
       (evil +everywhere)
       file-templates
       fold
       snippets
       (whitespace +guess +trim)

       :emacs
       dired
       electric
       tramp
       undo
       vc

       :checkers
       syntax

       :tools
       (eval +overlay)
       lookup
       magit

       :lang
       emacs-lisp
       lua
       markdown
       (org +pretty)       ; org-mode con extras visuales
       python
       sh

       :config
       (default +bindings +smartparens))
