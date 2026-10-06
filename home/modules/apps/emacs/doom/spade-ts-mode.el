;;; spade-ts-mode.el --- Tree-sitter major mode for Spade -*- lexical-binding: t; -*-

;; Minimal major mode for the Spade HDL (https://spade-lang.org) using the
;; tree-sitter-spade grammar (codeberg.org/spade-lang/tree-sitter-spade,
;; d094381, provided by Nix as the `spade' treesit language).
;;
;; Highlighting is translated from the Zed extension's highlights.scm
;; (codeberg.org/spade-lang/zed-spade), which targets the same grammar commit.

;;; Code:

(require 'treesit)

(defgroup spade-ts nil
  "Tree-sitter support for Spade."
  :group 'languages)

(defcustom spade-ts-mode-indent-offset 4
  "Number of spaces for each indentation step in `spade-ts-mode'."
  :type 'integer
  :safe 'integerp
  :group 'spade-ts)

(defvar spade-ts-mode--keywords
  '("pub" "unsafe" "pipeline" "let" "set" "entity" "for" "fn" "reg"
    "initial" "reset" "inst" "assert" "struct" "enum" "trait" "type"
    "stage" "wire" "impl" "port" "decl" "mod" "as" "where" "extern"
    "use" "gen" "if" "else" "match" "lib" "super")
  "Spade keywords, as anonymous nodes in the grammar.")

(defvar spade-ts-mode--operators
  '("&" "*" "inv" "-" "=>" ">" "<" "=" "->" "~" "!" "@" "+" "|"
    "==" "!=" "<=" ">=")
  "Spade operator tokens, as anonymous nodes in the grammar.")

(defvar spade-ts-mode--operator-nodes
  '(op_add op_sub op_mul op_div op_mod op_equals op_ne op_lt op_gt op_le op_ge
    op_lshift op_rshift op_wadd op_wsub op_wmul op_wlshift op_wrshift
    op_bitwise_and op_bitwise_xor op_bitwise_or op_logical_and op_logical_or
    op_custom_infix)
  "Named operator nodes in the grammar.")

(defvar spade-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'spade
   :feature 'comment
   '((line_comment) @font-lock-comment-face
     (block_comment) @font-lock-comment-face
     (doc_comment) @font-lock-doc-face)

   :language 'spade
   :feature 'keyword
   `([,@spade-ts-mode--keywords] @font-lock-keyword-face
     (pipeline_reg_marker) @font-lock-keyword-face
     (self) @font-lock-builtin-face)

   :language 'spade
   :feature 'preprocessor
   '((attribute) @font-lock-preprocessor-face
     (gen_if_expression ["if" "else"] @font-lock-preprocessor-face)
     (naked_gen_if_expression ["if" "else"] @font-lock-preprocessor-face))

   :language 'spade
   :feature 'definition
   '((unit_definition (identifier) @font-lock-function-name-face)
     (parameter (identifier) @font-lock-variable-name-face))

   :language 'spade
   :feature 'label
   '((pipeline_stage_name) @font-lock-constant-face
     (stage_reference stage: (identifier) @font-lock-constant-face))

   :language 'spade
   :feature 'constant
   '((bool_literal) @font-lock-constant-face
     ((identifier) @font-lock-builtin-face
      (:match "\\`\\(?:Some\\|None\\)\\'" @font-lock-builtin-face))
     ((identifier) @font-lock-constant-face
      (:match "\\`[A-Z][A-Z0-9_]*\\'" @font-lock-constant-face)))

   :language 'spade
   :feature 'type
   '((builtin_type) @font-lock-type-face
     (generic_param meta: _ @font-lock-type-face)
     ((identifier) @font-lock-type-face
      (:match "\\`[A-Z]" @font-lock-type-face)))

   :language 'spade
   :feature 'number
   '((int_literal) @font-lock-number-face)

   :language 'spade
   :feature 'string
   '((string_literal) @font-lock-string-face
     (char_literal) @font-lock-string-face)

   :language 'spade
   :feature 'property
   '((field_access _ (identifier) @font-lock-property-use-face)
     (method_call name: (identifier) @font-lock-function-call-face))

   :language 'spade
   :feature 'operator
   `([,@spade-ts-mode--operators] @font-lock-operator-face
     [,@(mapcar #'list spade-ts-mode--operator-nodes)] @font-lock-operator-face)

   :language 'spade
   :feature 'bracket
   '(["(" ")" "[" "]" "{" "}" "$(" "::<" "::$<"] @font-lock-bracket-face)

   :language 'spade
   :feature 'delimiter
   '(["::" ":" "." "," ";"] @font-lock-delimiter-face))
  "Tree-sitter font-lock settings for `spade-ts-mode'.")

(defvar spade-ts-mode--indent-rules
  `((spade
     ((node-is ")") parent-bol 0)
     ((node-is "]") parent-bol 0)
     ((node-is "}") parent-bol 0)
     ((parent-is "source_file") column-0 0)
     ((parent-is ,(regexp-opt '("block" "match_block" "enum_body" "impl" "trait"
                                "mod" "use_subtree" "parameter_list"
                                "braced_parameter_list" "argument_list"
                                "array_literal" "tuple_literal" "generic_list")))
      parent-bol spade-ts-mode-indent-offset)
     ((parent-is "comment") prev-adaptive-prefix 0)
     (no-node parent-bol 0)
     (catch-all parent-bol 0)))
  "Tree-sitter indentation rules for `spade-ts-mode'.")

(defvar spade-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?_ "_" table)
    (modify-syntax-entry ?' "." table)
    table)
  "Syntax table for `spade-ts-mode'.")

;;;###autoload
(define-derived-mode spade-ts-mode prog-mode "Spade"
  "Major mode for editing Spade, powered by tree-sitter."
  :group 'spade-ts
  :syntax-table spade-ts-mode--syntax-table
  (when (treesit-ready-p 'spade)
    (treesit-parser-create 'spade)

    (setq-local comment-start "// ")
    (setq-local comment-end "")
    (setq-local comment-start-skip (rx "//" (* "/") (* (syntax whitespace))))

    (setq-local treesit-font-lock-settings spade-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                '((comment definition)
                  (keyword preprocessor string type)
                  (constant label number property)
                  (bracket delimiter operator)))

    (setq-local indent-tabs-mode nil)
    (setq-local treesit-simple-indent-rules spade-ts-mode--indent-rules)

    (setq-local treesit-defun-type-regexp
                (regexp-opt '("unit_definition" "struct_definition" "enum_definition"
                              "impl" "trait" "mod")))

    (treesit-major-mode-setup)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.spade\\'" . spade-ts-mode))

;;; swim (https://codeberg.org/spade-lang/swim)

(defun spade-swim-root ()
  "Directory containing the nearest swim.toml, or signal an error."
  (or (locate-dominating-file (or buffer-file-name default-directory) "swim.toml")
      (user-error "No swim.toml above %s" default-directory)))

(defun spade-swim-run (args)
  "Run `swim ARGS' from the project root in a compilation buffer.
Uses the current buffer's environment, so a direnv dev shell provides swim."
  (let ((default-directory (spade-swim-root)))
    (compile (concat "swim " args))))

(defmacro spade-swim--defcommand (name args doc)
  `(defun ,(intern (format "spade-swim-%s" name)) ()
     ,doc
     (interactive)
     (spade-swim-run ,args)))

(spade-swim--defcommand build "build" "Compile the Spade code (swim build).")
(spade-swim--defcommand synth "synth" "Compile and synthesize (swim synth).")
(spade-swim--defcommand pnr "pnr" "Compile, synthesize and place-and-route (swim pnr).")
(spade-swim--defcommand upload "upload" "Build, pack and upload to the board (swim upload).")
(spade-swim--defcommand test "test" "Run the cocotb test benches (swim test).")
(spade-swim--defcommand clean "clean" "Remove build artefacts (swim clean).")

(defun spade-swim--toml-section (section)
  "Alist of string key/values in [SECTION] of the project's swim.toml."
  (with-temp-buffer
    (insert-file-contents (expand-file-name "swim.toml" (spade-swim-root)))
    (goto-char (point-min))
    (let (alist)
      (when (re-search-forward (format "^\\[%s\\][ \t]*$" (regexp-quote section)) nil t)
        (let ((end (save-excursion (if (re-search-forward "^\\[" nil t)
                                       (line-beginning-position)
                                     (point-max)))))
          (while (re-search-forward
                  "^[ \t]*\\([A-Za-z_]+\\)[ \t]*=[ \t]*\"\\([^\"]*\\)\"" end t)
            (push (cons (match-string 1) (match-string 2)) alist))))
      alist)))

(defun spade-swim--ecp5-device-flag (device)
  "nextpnr-ecp5 size flag for DEVICE, e.g. \"LFE5U-25F\" -> \"--25k\"."
  (unless (string-match "\\`LFE5\\(U\\|UM\\|UM5G\\)-\\([0-9]+\\)F\\'" device)
    (user-error "Unrecognised ECP5 device %S in swim.toml" device))
  (format "--%s%sk"
          (pcase (match-string 1 device) ("U" "") ("UM" "um-") ("UM5G" "um5g-"))
          (match-string 2 device)))

(defun spade-swim-nextpnr-gui ()
  "Open the nextpnr GUI on build/hardware.json using swim.toml's [pnr] settings.
Run `spade-swim-pnr' (or `spade-swim-synth') first to produce the netlist."
  (interactive)
  (let* ((default-directory (spade-swim-root))
         (pnr (spade-swim--toml-section "pnr"))
         (get (lambda (k) (or (cdr (assoc k pnr))
                              (user-error "swim.toml [pnr] has no %s" k))))
         (json "build/hardware.json"))
    (unless (equal (funcall get "architecture") "ecp5")
      (user-error "Only ECP5 is supported (architecture = %s)" (funcall get "architecture")))
    (unless (file-exists-p json)
      (user-error "%s not found; run swim synth/pnr first" json))
    (let ((cmd (append (list "nextpnr-ecp5" "--gui"
                             (spade-swim--ecp5-device-flag (funcall get "device"))
                             "--package" (funcall get "package")
                             "--json" json
                             "--lpf" (funcall get "pin_file"))
                       (when-let* ((speed (cdr (assoc "speed_grade" pnr))))
                         (list "--speed" speed)))))
      (message "%s" (string-join cmd " "))
      (apply #'start-process "nextpnr-gui" "*nextpnr-gui*" cmd))))

(provide 'spade-ts-mode)
;;; spade-ts-mode.el ends here
