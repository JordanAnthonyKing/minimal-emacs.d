;;; angular-ts-mode.el --- tree-sitter support for Angular flavoured HTML  -*- lexical-binding: t; -*-

;;; Commentary:
;;

;;; Code:

(require 'cl-lib)
(require 'treesit)
(require 'sgml-mode)
;; (require 'html-mode)

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-search-subtree "treesit.c")

(add-to-list
 'treesit-language-source-alist
 '(angular "https://github.com/dlvandenberg/tree-sitter-angular"
           :commit "843525141575e397541e119698f0532755e959f6")
 t)

(defcustom angular-ts-mode-indent-offset 2
  "Number of spaces for each indentation step in `angular-ts-mode'."
  :version "29.1"
  :type 'integer
  :safe 'integerp
  :group 'html)

(defvar angular-ts-mode--indent-rules
  `((angular
     ;; From html-ts-mode
     ((parent-is "fragment") column-0 0)
     ((node-is "/>") parent-bol 0)
     ((node-is ">") parent-bol 0)
     ((node-is "end_tag") parent-bol 0)
     ((parent-is "comment") prev-adaptive-prefix 0)
     ((parent-is "element") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "script_element") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "style_element") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "start_tag") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "self_closing_tag") parent-bol angular-ts-mode-indent-offset)
     ;; For angular
     ((parent-is "statement_block") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "switch_statement") parent-bol angular-ts-mode-indent-offset)
     ((node-is "{") parent-bol 0)
     ((node-is "}") parent-bol 0)))
  "Tree-sitter indent rules for `angular-ts-mode'.")

(defvar angular-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   ;; From html-ts-mode
   :language 'angular
   :override t
   :feature 'comment
   `((comment) @font-lock-comment-face)
   :language 'angular
   :override t
   :feature 'keyword1
   `("doctype" @font-lock-keyword-face)
   :language 'angular
   :override t
   :feature 'definition
   `((tag_name) @font-lock-function-name-face)
   :language 'angular
   :override t
   :feature 'string
   `((quoted_attribute_value) @font-lock-string-face)
   :language 'angular
   :override t
   :feature 'property
   `((attribute_name) @font-lock-variable-name-face)
   ;; For Angular
   :language 'angular
   :override t
   :feature 'property
   `((identifier) @font-lock-variable-name-face)
   :language 'angular
   :override t
   :feature 'operator
   `((pipe_operator) @font-lock-operator-face)
   :language 'angular
   :override t
   :feature 'string
   `(([(string) (static_member_expression)]) @font-lock-string-face)
   :language 'angular
   :override t
   :feature 'number
   `((number) @font-lock-number-face)
   :language 'angular
   :override t
   :feature 'function
   `((pipe_call
      name: (identifier) @font-lock-function-call-face))
   :language 'angular
   :override t
   :feature 'parameter
   `((pipe_call
      arguments: (pipe_arguments
                  (identifier) @font-lock-variable-use-face)))
   :language 'angular
   :override t
   :feature 'keyword
   `((structural_directive
      "*" @font-lock-keyword-face
      (identifier) @font-lock-keyword-face))
   :language 'angular
   :override t
   :feature 'property
   `((attribute
      ((attribute_name) @font-lock-property-name-face
       (:match "#.*" @font-lock-property-name-face))))
   :language 'angular
   :override t
   :feature 'keyword
   `((binding_name (identifier) @font-lock-keyword-face)
     (event_binding (binding_name (identifier) @font-lock-keyword-face)))
   :language 'angular
   :override t
   :feature 'delimiter
   `((event_binding "\"" @font-lock-delimiter-face)
     (property_binding "\"" @font-lock-delimiter-face))
   :language 'angular
   :override t
   :feature 'keyword
   `((structural_assignment operator: (identifier) @font-lock-keyword-face))
   :language 'angular
   :override t
   :feature 'property
   `((member_expression property: (identifier) @font-lock-property-name-face))
   :language 'angular
   :override t
   :feature 'function
   `((call_expression function: (identifier) @font-lock-function-name-face))
   :language 'angular
   :override t
   :feature 'function
   `((call_expression function: ((identifier) @font-lock-builtin-face
                                 (:equal "$any" @font-lock-builtin-face))))
   :language 'angular
   :override t
   :feature 'pair
   `((pair
      key: ((identifier) @font-lock-builtin-face
            (:equal "$implicit" @font-lock-builtin-face))))
   :language 'angular
   :override t
   :feature 'keyword
   `(([(control_keyword) (special_keyword)]) @font-lock-keyword-face)
   :language 'angular
   :override t
   :feature 'keyword
   `(((control_keyword) @font-lock-keyword-face
      (:match "for\\|empty" @font-lock-keyword-face)))
   :language 'angular
   :override t
   :feature 'keyword
   `(((control_keyword) @font-lock-keyword-face)
     (:match "if\\|else\\|switch\\|case\\|default" @font-lock-keyword-face))
   :language 'angular
   :override t
   :feature 'keyword
   `(((control_keyword) @font-lock-keyword-face
      (:match "defer\\|placeholder\\|loading" @font-lock-keyword-face)))
   :language 'angular
   :override t
   :feature 'keyword
   `(((control_keyword) @font-lock-warning-face
      (:equal "error" @font-lock-warning-face)))
   :language 'angular
   :override t
   :feature 'boolean
   `(((identifier) @font-lock-builtin-face
      (:match "true\\|false" @font-lock-builtin-face)))
   :language 'angular
   :override t
   :feature 'builtin
   `(((identifier) @font-lock-builtin-face
      (:match "this\\|$event" @font-lock-builtin-face)))
   :language 'angular
   :override t
   :feature 'builtin
   `(((identifier) @font-lock-constant-face
      (:equal "null" @font-lock-constant-face)))
   :language 'angular
   :override t
   :feature 'operator
   `(([(ternary_operator) (conditional_operator)]) @font-lock-operator-face)
   ;; :language 'angular
   ;; :override t
   ;; :feature 'punctuation1
   ;; `(["{{" "}}"] @font-lock-escape-face)
   ;; :language 'angular
   ;; :override t
   ;; :feature 'punctuation1
   ;; `(interpolation (("{{" @font-lock-escape-face)
   ;;                  ("}}" @font-lock-escape-face)))
   :language 'angular
   :override t
   :feature 'punctuation
   `(["(" ")" "[" "]" "{" "}" "@"] @font-lock-escape-face)
   :language 'angular
   :override t
   :feature 'punctuation3
   `((two_way_binding (["[(" ")]"] @font-lock-punctuation-face)))
   :language 'angular
   :override t
   :feature 'punctuation2
   `((template_substitution (["${" "}"] @font-lock-escape-face)))
   :language 'angular
   :override t
   :feature 'string
   `((template_chars) @font-lock-string-face)
   :language 'angular
   :override t
   :feature 'delimiter
   `(([";" "." "," "?."]) @font-lock-delimiter-face)
   :language 'angular
   :override t
   :feature 'operator
   `((nullish_coalescing_expression (coalescing_operator) @font-lock-operator-face)
     (concatenation_expression "+" @font-lock-operator-face)
     (icu_clause) @font-lock-operator-face)
   :language 'angular
   :override t
   :feature 'keyword
   `((icu_category) @font-lock-keyword-face)
   :language 'angular
   :override t
   :feature 'operator
   `((["-" "&&" "+" "<" "<=" "=" "==" "===" "!=" "!==" ">" ">=" "*" "/" "||" "%"]) @font-lock-operator-face))
  "Tree-sitter font-lock settings for `angular-ts-mode'.")

(defvar angular-ts-mode--treesit-things-settings
  `((angular
     ;; sexp: basically all nodes except document root and tag_name
     (sexp (not (or (and named ,(rx bos (or "document" "tag_name") eos))
                    (and anonymous ,(rx (or "<!" "<" ">" "</"))))))
     ;; list: HTML elements + Angular control flow blocks
     (list ,(rx (or "doctype" "element" "comment" "control_keyword")))
     ;; sentences: tag names or attributes
     (sentence ,(rx (and bos (or "tag_name" "attribute") eos)))
     ;; text nodes: comments or interpolations
     (text ,(regexp-opt '("comment" "text" "template_substitution"))))))

(defvar angular-ts-mode--treesit-font-lock-feature-list
  '((comment keyword definition)
    (string property number function parameter boolean builtin)
    (operator delimiter pair punctuation punctuation2 punctuation3)
    ())
  "Settings for `treesit-font-lock-feature-list'.")

(defvar angular-ts-mode--treesit-simple-imenu-settings
  '((nil "element" nil nil))
  "Settings for `treesit-simple-imenu'.")

(defvar angular-ts-mode--treesit-defun-type-regexp
  "element"
  "Settings for `treesit-defun-type-regexp'.")

(defun angular-ts-mode--defun-name (node)
  "Return the defun name of NODE.
Return nil if there is no name or if NODE is not a defun node."
  (when (string-match-p "element" (treesit-node-type node))
    (treesit-node-text
     (treesit-search-subtree node "\\`tag_name\\'" nil nil 2)
     t)))

(declare-function treesit-node-end "treesit.c")
(declare-function treesit-node-start "treesit.c")

(defun angular-ts-mode--outline-predicate (node)
  "Limit outlines to multi-line elements."
  (when (string-match-p "element" (treesit-node-type node))
    (< (save-excursion
         (goto-char (treesit-node-start node))
         (pos-bol))
       (save-excursion
         (goto-char (treesit-node-end node))
         (skip-chars-backward " \t\n")
         (pos-bol)))))


;;;###autoload
(define-derived-mode angular-ts-mode html-mode "Angular"
  "Major mode for editing Html, powered by tree-sitter."
  :group 'angular

  (unless (treesit-ensure-installed 'angular)
    (error "Tree-sitter for Angular isn't available"))

  (setq treesit-primary-parser (treesit-parser-create 'angular))

  ;; Indent.
  (setq-local treesit-simple-indent-rules angular-ts-mode--indent-rules)

  ;; Navigation.
  (setq-local treesit-defun-type-regexp angular-ts-mode--treesit-defun-type-regexp)

  (setq-local treesit-defun-name-function #'angular-ts-mode--defun-name)

  (setq-local treesit-thing-settings angular-ts-mode--treesit-things-settings)

  ;; Font-lock.
  (setq-local treesit-font-lock-settings angular-ts-mode--font-lock-settings)
  (setq-local treesit-font-lock-feature-list angular-ts-mode--treesit-font-lock-feature-list)

  ;; Imenu.
  (setq-local treesit-simple-imenu-settings angular-ts-mode--treesit-simple-imenu-settings)

  ;; Outline minor mode.
  (setq-local treesit-outline-predicate #'angular-ts-mode--outline-predicate)
  ;; `angular-ts-mode' inherits from `html-mode' that sets
  ;; regexp-based outline variables.  So need to restore
  ;; the default values of outline variables to be able
  ;; to use `treesit-outline-predicate' above.
  (kill-local-variable 'outline-regexp)
  (kill-local-variable 'outline-heading-end-regexp)
  (kill-local-variable 'outline-level)

  (add-to-list 'find-sibling-rules
               '("\\(.+\\)\\.\\(component\\|container\\)\\.html" "\\1.\\2.ts"))

  (treesit-major-mode-setup))

(derived-mode-add-parents 'angular-ts-mode '(html-mode))

(if (treesit-ready-p 'angular)
    (add-to-list 'auto-mode-alist
                 '("\\.\\(component\\|container\\)\\.html\\'" . angular-ts-mode)))


(provide 'angular-ts-mode)

;;; angular-ts-mode.el ends here
