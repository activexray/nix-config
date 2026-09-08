;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

(package! nyan-mode)
(package! catppuccin-theme)
;; Using YTG123's fork/branch until upstream merges the autoload fix for
;; https://codeberg.org/meow_king/typst-ts-mode/issues/103 (PR #106):
;; a bare `;;;###autoload' cookie on `define-compilation-mode' gets inlined
;; into the autoloads file and crashes Doom startup on Emacs 31+ with
;; "Symbol's function definition is void: define-compilation-mode".
(package! typst-ts-mode :recipe
  (:host codeberg
   :repo "YTG123/typst-ts-mode"
   :branch "fix-autoload")
  :pin "00048014025fc51c5c910727623d147b9a899d8c")
