;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Personal information
(setq user-full-name "Kiran Shila" user-mail-address "me@kiranshila.com")

;; Fix Shell
(setq shell-file-name (executable-find "bash"))
(setq-default vterm-shell (executable-find "fish"))

;; Fix SSH Agent
(when (executable-find "gpgconf")
  (setenv "SSH_AUTH_SOCK" (string-trim (shell-command-to-string "gpgconf --list-dirs agent-ssh-socket"))))

;; Make sure the theme is loaded
(use-package! catppuccin-theme
  :config
  (load-theme 'catppuccin t t)
  (setq! catppuccin-flavor 'macchiato)
  (catppuccin-reload))

(setq display-line-numbers-type t)
(setq doom-theme 'catppuccin
      doom-font (font-spec :family "Iosevka Term SS09" :size 16)
      doom-symbol-font (font-spec :family "JuliaMono" :size 16)
      doom-variable-pitch-font (font-spec :family "Iosevka Aile" :size 16)
      doom-serif-font (font-spec :family "Iosevka Slab" :size 16))

;; Nyan Nyan
(after! doom-modeline (nyan-mode))

;; Plenty O' Ram
(setq so-long-threshold 9000)

;; Buffer and window nav
(map!
 :leader
 (:prefix "b"
  :desc "Previous buffer" :n "p" #'previous-buffer
  :desc "Next buffer" :n "n" #'next-buffer
  :desc "Switch buffer" :n "b" #'switch-to-buffer)
 (:prefix "w"
  :desc "Vertical split" :n "/" #'evil-window-vsplit
  :desc "Horizontal split" :n "-" #'evil-window-split
  :desc "New frame" :n "F" #'make-frame
  :desc "Next frame" :n "o" #'other-frame
  :desc "Delete window" :n "d" #'evil-quit))

;; Remap SPC M to ,
(map! :n "," (cmd! (push (cons t ?m) unread-command-events)
                   (push (cons t 32) unread-command-events)))

;; Smartparens off hyper
(map!
 :ni "C-M-s-s" #'sp-forward-slurp-sexp
 :ni "C-M-s-S" #'sp-backward-slurp-sexp
 :ni "C-M-s-b" #'sp-forward-barf-sexp
 :ni "C-M-s-B" #'sp-backward-barf-sexp
 :ni "C-M-s-c" #'sp-convolute-sexp
 :ni "C-M-s-t" #'sp-transpose-sexp
 :ni "C-M-s-r" #'sp-raise-sexp
 :ni "C-M-s-w" #'sp-wrap-round
 :ni "C-M-s-u" #'sp-unwrap-sexp
 :ni "C-M-s-[" #'sp-wrap-square
 :ni "C-M-s-{" #'sp-wrap-curly
 :ni "C-M-s-j" #'sp-join-sexp
 :ni "C-M-s-|" #'sp-split-sexp)

(setq projectile-project-search-path `("~/sync/Projects" "~/src"))

(setq org-directory "~/sync/org/")

(after! cider
  (setq cider-repl-pop-to-buffer-on-connect t))

;; Inlay hints for all LSP-managed buffers
(after! eglot
  (add-hook 'eglot-managed-mode-hook #'eglot-inlay-hints-mode))

;; Enable horizontal scrolling
(setq mouse-wheel-tilt-scroll t)
(setq mouse-wheel-flip-direction t)

;; Fix error when there are no staged changes
(after! diff-hl
  (advice-add 'diff-hl-changes-from-buffer :around
              #'ignore-errors))
(setq +latex-viewers '(pdf-tools))

;; TOML
(after! eglot
  (add-to-list 'eglot-server-programs '(toml-ts-mode . ("taplo" "lsp" "stdio"))))

(use-package! toml-ts-mode
  :mode "\\.toml\\'"
  :config
  (add-hook 'toml-ts-mode-local-vars-hook #'lsp! 'append))

;; Eglot configuration
(after! eglot
  ;; Workspace configuration for language servers
  (setq-default eglot-workspace-configuration
                '(:rust-analyzer
                  (:check (:command "clippy")
                   :procMacro (:enable t)
                   :inlayHints (:chainingHints (:enable t)
                                :maxLength 25))
                  nil
                  (:formatting (:command ["alejandra" "--"])))))

(after! eglot
  (add-to-list 'eglot-server-programs
               '(typst-ts-mode . ("tinymist"
                                  :initializationOptions
                                  (:exportPdf "onSave")))))

(use-package! typst-ts-mode
  :defer t
  :init
  (add-to-list 'auto-mode-alist '("\\.typ\\'" . typst-ts-mode))
  :custom
  (typst-ts-watch-options "--open")
  (typst-ts-mode-enable-raw-blocks-highlight t)
  (typst-ts-fontification-precision-level 'max)
  :config
  (add-hook 'typst-ts-mode-local-vars-hook #'lsp! 'append)
  (set-formatter! 'typstyle '("typstyle") :modes '(typst-ts-mode))
  (setq-hook! 'typst-ts-mode-hook +format-with 'typstyle)
  (set-popup-rule! "^\\*typst-ts-compilation\\*"
    :side 'bottom :size 0.5 :select nil :ttl t)
  (map!
   (:localleader
    :map typst-ts-mode-map
    :desc "Compile document" "c" #'typst-ts-compile
    :desc "Preview document" "p" #'typst-ts-mode-preview
    :desc "Watch document" "w" #'typst-ts-watch-mode)))
