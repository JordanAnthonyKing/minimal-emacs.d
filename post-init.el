;;; post-init.el --- post-init -*- no-byte-compile: t; lexical-binding: t; -*-

(setq custom-file null-device)

;; Allow Emacs to upgrade built-in packages, such as Org mode
(setq package-install-upgrade-built-in t)


;; Set the default font to DejaVu Sans Mono with specific size and weight
(set-face-attribute 'default nil
                    :height 120 :weight 'normal :family "Berkeley Mono SemiCondensed")

(use-package general
  :ensure (:wait t)
  :demand t)

(use-package doom-themes
  :ensure t
  :custom
  ;; Global settings (defaults)
  (doom-themes-enable-bold t)   ; if nil, bold is universally disabled
  (doom-themes-enable-italic t) ; if nil, italics is universally disabled
  ;; (doom-themes-padded-modeline t)
  ;; for treemacs users
  ;; (doom-themes-treemacs-theme "doom-atom") ; use "doom-colors" for less minimal icon theme
  :config
  (load-theme 'doom-one t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Enable custom neotree theme (nerd-icons must be installed!)
  ;; (doom-themes-neotree-config)
  ;; or for treemacs users
  ;; (doom-themes-treemacs-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

(use-package diminish :ensure t)

(use-package no-littering)

;; Native compilation enhances Emacs performance by converting Elisp code into
;; native machine code, resulting in faster execution and improved
;; responsiveness.
;;
;; Ensure adding the following compile-angel code at the very beginning
;; of your `~/.emacs.d/post-init.el` file, before all other packages.
(use-package compile-angel
  :ensure t
  :diminish compile-angel-on-save-mode
  :custom
  ;; Set `compile-angel-verbose` to nil to suppress output from compile-angel.
  ;; Drawback: The minibuffer will not display compile-angel's actions.
  (compile-angel-verbose t)
  :config
  ;; The following directive prevents compile-angel from compiling your init
  ;; files. If you choose to remove this push to `compile-angel-excluded-files'
  ;; and compile your pre/post-init files, ensure you understand the
  ;; implications and thoroughly test your code. For example, if you're using
  ;; `use-package', you'll need to explicitly add `(require 'use-package)` at
  ;; the top of your init file.
  (push "/init.el" compile-angel-excluded-files)
  (push "/early-init.el" compile-angel-excluded-files)
  (push "/post-init.el" compile-angel-excluded-files)

  ;; A local mode that compiles .el files whenever the user saves them.
  ;; (add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode)

  ;; A global mode that compiles .el files prior to loading them via `load' or
  ;; `require'. Additionally, it compiles all packages that were loaded before
  ;; the mode `compile-angel-on-load-mode' was activated.
  (compile-angel-on-save-mode 1))

(defvar doom-escape-hook nil
  "A hook run when C-g is pressed (or ESC in normal mode, for evil users).

More specifically, when `doom/escape' is pressed. If any hook returns non-nil,
all hooks after it are ignored.")

(defun doom/escape (&optional interactive)
  "Run `doom-escape-hook'."
  (interactive (list 'interactive))
  (let ((inhibit-quit t))
    (cond ((minibuffer-window-active-p (minibuffer-window))
           ;; quit the minibuffer if open.
           (when interactive
             (setq this-command 'abort-recursive-edit))
           (abort-recursive-edit))
          ;; Run all escape hooks. If any returns non-nil, then stop there.
          ((run-hook-with-args-until-success 'doom-escape-hook))
          ;; don't abort macros
          ((or defining-kbd-macro executing-kbd-macro) nil)
          ;; Back to the default
          ((unwind-protect (keyboard-quit)
             (when interactive
               (setq this-command 'keyboard-quit)))))))

(global-set-key [remap keyboard-quit] #'doom/escape)

(with-eval-after-load 'eldoc
  (eldoc-add-command 'doom/escape))

(use-package avy
  :ensure t
  :commands (avy-goto-char
             avy-goto-char-2
             avy-next)
  :init
  (global-set-key (kbd "C-'") 'avy-goto-char-2))

;; The undo-fu package is a lightweight wrapper around Emacs' built-in undo
;; system, providing more convenient undo/redo functionality.
(use-package undo-fu
  :ensure t
  :commands (undo-fu-only-undo
             undo-fu-only-redo
             undo-fu-only-redo-all
             undo-fu-disable-checkpoint)
  :config
  (global-unset-key (kbd "C-z"))
  (global-set-key (kbd "C-z") 'undo-fu-only-undo)
  (global-set-key (kbd "C-S-z") 'undo-fu-only-redo))

;; The undo-fu-session package complements undo-fu by enabling the saving
;; and restoration of undo history across Emacs sessions, even after restarting.
(use-package undo-fu-session
  :ensure t
  :commands undo-fu-session-global-mode
  :hook (after-init . undo-fu-session-global-mode))

(use-package vundo
  :ensure t
  :commands vundo
  :config
  (setq vundo-glyph-alist vundo-unicode-symbols
        ;; vundo-compact-display t
        vundo-compact-display nil)
  (define-key vundo-mode-map [remap doom/escape] #'vundo-quit))

(use-package repeat
  :defer t
  :ensure nil
  :config (add-hook 'dape-on-start-hooks #'repeat-mode)
  :custom
  (repeat-too-dangerous '(kill-this-buffer))
  (repeat-exit-timeout 5))

;; Uncomment the following if you are using undo-fu
(setq evil-undo-system 'undo-fu)

(defun +evil/shift-left ()
  "vnoremap > >gv"
  (interactive)
  (call-interactively #'evil-shift-left)
  (evil-normal-state)
  (evil-visual-restore))

(defun +evil/shift-right ()
  "vnoremap < <gv"
  (interactive)
  (call-interactively #'evil-shift-right)
  (evil-normal-state)
  (evil-visual-restore))

(defun my/consult-buffer-or-project ()
  "Call `consult-project-buffer` if in a project, else `consult-buffer`."
  (interactive)
  (if (project-current)
      (consult-project-buffer)
    (consult-buffer)))

;; Vim emulation
(use-package evil
  :ensure t
  :commands (evil-mode evil-define-key)
  :hook (after-init . evil-mode)
  :init
  ;; It has to be defined before evil
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  :general (:states '(motion normal visual operator)
                    :keymaps 'override
                    "SPC" #'my/consult-buffer-or-project)
  (:states '(motion normal visual)
           "s" #'evil-avy-goto-char-timer
           "gh" help-map)
  (:states '(visual)
           "<" #'+evil/shift-left
           ">" #'+evil/shift-right)
  :custom
  ;; Make :s in visual mode operate only on the actual visual selection
  ;; (character or block), instead of the full lines covered by the selection
  (evil-ex-visual-char-range t)
  ;; Use Vim-style regular expressions in search and substitute commands,
  ;; allowing features like \v (very magic), \zs, and \ze for precise matches
  (evil-ex-search-vim-style-regexp t)
  ;; Enable automatic horizontal split below
  (evil-split-window-below t)
  ;; Enable automatic vertical split to the right
  (evil-vsplit-window-right t)
  ;; Disable echoing Evil state to avoid replacing eldoc
  (evil-echo-state nil)
  ;; Do not move cursor back when exiting insert state
  (evil-move-cursor-back nil)
  ;; Make `v$` exclude the final newline
  (evil-v$-excludes-newline t)
  ;; Allow C-h to delete in insert state
  (evil-want-C-h-delete t)
  ;; Enable C-u to delete back to indentation in insert state
  (evil-want-C-u-delete t)
  ;; Enable fine-grained undo behavior
  (evil-want-fine-undo t)
  ;; Allow moving cursor beyond end-of-line in visual block mode
  (evil-move-beyond-eol t)
  ;; Disable wrapping of search around buffer
  ;; (evil-search-wrap nil)
  ;; Whether Y yanks to the end of the line
  (evil-want-Y-yank-to-eol t)
  :config
  (setq evil-visual-update-x-selection-p nil)

  (defun save-and-kill-this-buffer()(interactive)(save-buffer)(kill-current-buffer))
  (evil-ex-define-cmd "wq" 'save-and-kill-this-buffer)
  (evil-ex-define-cmd "q"  'kill-current-buffer)

  (add-hook 'after-change-major-mode-hook
            (lambda ()
              (setq-local evil-shift-width tab-width)))

  (defun +evil-disable-ex-highlights-h ()
    "Disable ex search buffer highlights."
    (when (evil-ex-hl-active-p 'evil-ex-search)
      (evil-ex-nohighlight)
      t))

  (add-hook 'doom-escape-hook #'+evil-disable-ex-highlights-h)

  (with-eval-after-load 'eldoc
    ;; Allow eldoc to trigger directly after changing modes
    (eldoc-add-command 'evil-normal-state
                       'evil-insert
                       'evil-change
                       'evil-delete
                       'evil-replace))

  (defun +evil--dont-move-cursor-a (fn &rest args)
    "Prevent the cursor from moving when `evil-indent` is called."
    (save-excursion
      (apply fn args)))

  (advice-add 'evil-indent :around #'+evil--dont-move-cursor-a)

  (defun +evil-escape-a (&rest _)
    "Call `doom/escape' if `evil-force-normal-state' is called interactively."
    (when (called-interactively-p 'any)
      (call-interactively #'doom/escape)))

  ;; Make ESC (from normal mode) the universal escaper. See `doom-escape-hook'.
  (advice-add #'evil-force-normal-state :after #'+evil-escape-a))

(use-package evil-collection
  :after evil
  :ensure t
  :init
  (setq evil-collection-want-unimpaired-p t)
  ;; It has to be defined before evil-colllection
  (setq evil-collection-setup-minibuffer t)
  :config
  (evil-collection-init))

;; Give Emacs tab-bar a style similar to Vim's
(use-package vim-tab-bar
  :ensure t
  :commands vim-tab-bar-mode
  :hook (after-init . vim-tab-bar-mode))

;; The evil-surround package simplifies handling surrounding characters, such as
;; parentheses, brackets, quotes, etc. It provides key bindings to easily add,
;; change, or delete these surrounding characters in pairs. For instance, you
;; can surround the currently selected text with double quotes in visual state
;; using S" or gS".
(use-package evil-surround
  :after evil
  :ensure t
  :commands global-evil-surround-mode
  :custom
  (evil-surround-pairs-alist
   '((?\( . ("(" . ")"))
     (?\[ . ("[" . "]"))
     (?\{ . ("{" . "}"))

     (?\) . ("(" . ")"))
     (?\] . ("[" . "]"))
     (?\} . ("{" . "}"))

     (?< . ("<" . ">"))
     (?> . ("<" . ">"))))
  :general
  (:states '(visual)
           "S"    #'evil-surround-region)
  (:states 'operator
           "s"    #'evil-surround-edit)
  :hook (after-init . global-evil-surround-mode))

(use-package evil-visualstar
  :ensure t
  :defer t
  :general
  (:states '(visual)
           "*" #'evil-visualstar/begin-search-forward
           "#" #'evil-visualstar/begin-search-backward)
  :commands (evil-visualstar/begin-search
             evil-visualstar/begin-search-forward
             evil-visualstar/begin-search-backward))

(use-package evil-matchit
  :after evil-collection
  :config
  (global-evil-matchit-mode 1))


(use-package evil-commentary
  :diminish evil-commentary-mode
  :after evil
  :init
  (evil-commentary-mode 1))

;; TODO: The rest
(use-package evil-textobj-tree-sitter
  :ensure t
  :after evil
  :init
  ;; bind `function.outer`(entire function block) to `f` for use in things like `vaf`, `yaf`
  (define-key evil-outer-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.outer"))
  ;; bind `function.inner`(function block without name and args) to `f` for use in things like `vif`, `yif`
  (define-key evil-inner-text-objects-map "f" (evil-textobj-tree-sitter-get-textobj "function.inner"))

  ;; You can also bind multiple items and we will match the first one we can find
  (define-key evil-outer-text-objects-map "a" (evil-textobj-tree-sitter-get-textobj ("conditional.outer" "loop.outer")))

  ;; Goto start of next function
  (define-key evil-normal-state-map
              (kbd "]f")
              (lambda ()
                (interactive)
                (evil-textobj-tree-sitter-goto-textobj "function.outer")))

  ;; Goto start of previous function
  (define-key evil-normal-state-map
              (kbd "[f")
              (lambda ()
                (interactive)
                (evil-textobj-tree-sitter-goto-textobj "function.outer" t)))

  ;; Goto end of next function
  (define-key evil-normal-state-map
              (kbd "]F")
              (lambda ()
                (interactive)
                (evil-textobj-tree-sitter-goto-textobj "function.outer" nil t)))

  ;; Goto end of previous function
  (define-key evil-normal-state-map
              (kbd "[F")
              (lambda ()
                (interactive)
                (evil-textobj-tree-sitter-goto-textobj "function.outer" t t)))
  
  )

(use-package visual-replace
  :defer t
  :bind (("C-c r" . visual-replace)
         :map isearch-mode-map
         ("C-c r" . visual-replace-from-isearch)))

;; Drag lines and regions around
(use-package drag-stuff
  :ensure t
  :diminish drag-stuff-mode
  :after evil
  :defer t
  :bind (:map evil-visual-state-map
	          ("C-j" . drag-stuff-down)
	          ("C-k" . drag-stuff-up)))

(use-package pulsar
  :hook (after-init . pulsar-global-mode)
  :config
  (setq pulsar-pulse t
        pulsar-delay 0.025
        pulsar-iterations 10
        pulsar-face 'pulsar-cyan
        pulsar-highlight-face 'evil-ex-lazy-highlight
        pulsar-pulse-functions '(
                                 evil-yank
                                 evil-yank-line
                                 evil-delete
                                 evil-delete-line
                                 evil-jump-item
                                 evil-scroll-down
                                 evil-scroll-up
                                 evil-scroll-page-down
                                 evil-scroll-page-up
                                 evil-scroll-line-down
                                 evil-scroll-line-up
                                 evil-window-up
                                 evil-window-rotate-upwards
                                 evil-window-rotate-downwards
                                 evil-window-down
                                 evil-window-left
                                 evil-window-right
                                 evil-window-vsplit
                                 evil-window-split)))

;; Auto-revert in Emacs is a feature that automatically updates the
;; contents of a buffer to reflect changes made to the underlying file
;; on disk.
(use-package autorevert
  :ensure nil
  :commands (auto-revert-mode global-auto-revert-mode)
  :hook
  (after-init . global-auto-revert-mode)
  :custom
  (auto-revert-interval 3)
  (auto-revert-remote-files nil)
  (auto-revert-use-notify t)
  (auto-revert-avoid-polling nil)
  (auto-revert-verbose t))

;; Recentf is an Emacs package that maintains a list of recently
;; accessed files, making it easier to reopen files you have worked on
;; recently.
(use-package recentf
  :ensure nil
  :commands (recentf-mode recentf-cleanup)
  :hook
  (after-init . recentf-mode)

  :custom
  (recentf-auto-cleanup (if (daemonp) 300 'never))
  (recentf-exclude
   (list "\\.tar$" "\\.tbz2$" "\\.tbz$" "\\.tgz$" "\\.bz2$"
         "\\.bz$" "\\.gz$" "\\.gzip$" "\\.xz$" "\\.zip$"
         "\\.7z$" "\\.rar$"
         "COMMIT_EDITMSG\\'"
         "\\.\\(?:gz\\|gif\\|svg\\|png\\|jpe?g\\|bmp\\|xpm\\)$"
         "-autoloads\\.el$" "autoload\\.el$"))

  :config
  ;; A cleanup depth of -90 ensures that `recentf-cleanup' runs before
  ;; `recentf-save-list', allowing stale entries to be removed before the list
  ;; is saved by `recentf-save-list', which is automatically added to
  ;; `kill-emacs-hook' by `recentf-mode'.
  (add-hook 'kill-emacs-hook #'recentf-cleanup -90))

;; savehist is an Emacs feature that preserves the minibuffer history between
;; sessions. It saves the history of inputs in the minibuffer, such as commands,
;; search strings, and other prompts, to a file. This allows users to retain
;; their minibuffer history across Emacs restarts.
(use-package savehist
  :ensure nil
  :commands (savehist-mode savehist-save)
  :hook
  (after-init . savehist-mode)
  :custom
  (savehist-autosave-interval 600)
  (savehist-additional-variables
   '(kill-ring                        ; clipboard
     register-alist                   ; macros
     mark-ring global-mark-ring       ; marks
     search-ring regexp-search-ring)))

;; save-place-mode enables Emacs to remember the last location within a file
;; upon reopening. This feature is particularly beneficial for resuming work at
;; the precise point where you previously left off.
(use-package saveplace
  :ensure nil
  :commands (save-place-mode save-place-local-mode)
  :hook
  (after-init . save-place-mode)
  :custom
  (save-place-limit 400))

;; Enable `auto-save-mode' to prevent data loss. Use `recover-file' or
;; `recover-session' to restore unsaved changes.
(setq auto-save-default t)

(setq auto-save-interval 300)
(setq auto-save-timeout 30)

(use-package buffer-terminator
  :ensure t
  :custom
  ;; Enable/Disable verbose mode to log buffer cleanup events
  (buffer-terminator-verbose nil)

  ;; Set the inactivity timeout (in seconds) after which buffers are considered
  ;; inactive (default is 30 minutes):
  (buffer-terminator-inactivity-timeout (* 30 60)) ; 30 minutes

  ;; Define how frequently the cleanup process should run (default is every 10
  ;; minutes):
  (buffer-terminator-interval (* 10 60)) ; 10 minutes

  :config
  (buffer-terminator-mode 1))

(unless (and (eq window-system 'mac)
             (bound-and-true-p mac-carbon-version-string))
  ;; Enables `pixel-scroll-precision-mode' on all operating systems and Emacs
  ;; versions, except for emacs-mac.
  ;;
  ;; Enabling `pixel-scroll-precision-mode' is unnecessary with emacs-mac, as
  ;; this version of Emacs natively supports smooth scrolling.
  ;; https://bitbucket.org/mituharu/emacs-mac/commits/65c6c96f27afa446df6f9d8eff63f9cc012cc738
  (setq pixel-scroll-precision-use-momentum nil) ; Precise/smoother scrolling
  (pixel-scroll-precision-mode 1))

;; Display the time in the modeline
(add-hook 'after-init-hook #'display-time-mode)

;; Paren match highlighting
(add-hook 'after-init-hook #'show-paren-mode)

;; Track changes in the window configuration, allowing undoing actions such as
;; closing windows.
(add-hook 'after-init-hook #'winner-mode)

(use-package uniquify
  :ensure nil
  :custom
  (uniquify-buffer-name-style 'reverse)
  (uniquify-separator "•")
  (uniquify-after-kill-buffer-p t))

;; Window dividers separate windows visually. Window dividers are bars that can
;; be dragged with the mouse, thus allowing you to easily resize adjacent
;; windows.
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Window-Dividers.html
(add-hook 'after-init-hook #'window-divider-mode)

(use-package dired
  :ensure nil
  :defer t
  :after evil-collection
  ;; :custom
  ;; (dired-listing-switches "-aBhl --group-directories-first")
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'dired-up-directory
    "l" 'dired-find-file))

;; Constrain vertical cursor movement to lines within the buffer
(setq dired-movement-style 'bounded-files)

;; Dired buffers: Automatically hide file details (permissions, size,
;; modification date, etc.) and all the files in the `dired-omit-files' regular
;; expression for a cleaner display.
(add-hook 'dired-mode-hook #'dired-hide-details-mode)

;; Hide files from dired
(setq dired-omit-files (concat "\\`[.]\\'"
                               "\\|\\(?:\\.js\\)?\\.meta\\'"
                               "\\|\\.\\(?:elc|a\\|o\\|pyc\\|pyo\\|swp\\|class\\)\\'"
                               "\\|^\\.DS_Store\\'"
                               "\\|^\\.\\(?:svn\\|git\\)\\'"
                               "\\|^\\.ccls-cache\\'"
                               "\\|^__pycache__\\'"
                               "\\|^\\.project\\(?:ile\\)?\\'"
                               "\\|^flycheck_.*"
                               "\\|^flymake_.*"))
(add-hook 'dired-mode-hook #'dired-omit-mode)

;; dired: Group directories first
(with-eval-after-load 'dired
  (let ((args "--group-directories-first -ahlv"))
    (when (or (eq system-type 'darwin) (eq system-type 'berkeley-unix))
      (if-let* ((gls (executable-find "gls")))
          (setq insert-directory-program gls)
        (setq args nil)))
    (when args
      (setq dired-listing-switches args))))

;; Enables visual indication of minibuffer recursion depth after initialization.
(add-hook 'after-init-hook #'minibuffer-depth-indicate-mode)

;; Configure Emacs to ask for confirmation before exiting
(setq confirm-kill-emacs 'y-or-n-p)

;; Enabled backups save your changes to a file intermittently
(setq make-backup-files t)
(setq vc-make-backup-files t)
(setq kept-old-versions 10)
(setq kept-new-versions 10)

;; When tooltip-mode is enabled, certain UI elements (e.g., help text,
;; mouse-hover hints) will appear as native system tooltips (pop-up windows),
;; rather than as echo area messages. This is useful in graphical Emacs sessions
;; where tooltips can appear near the cursor.
(setq tooltip-hide-delay 20)    ; Time in seconds before a tooltip disappears (default: 10)
(setq tooltip-delay 0.4)        ; Delay before showing a tooltip after mouse hover (default: 0.7)
(setq tooltip-short-delay 0.08) ; Delay before showing a short tooltip (Default: 0.1)
(tooltip-mode 1)

(use-package which-key
  :ensure nil ; builtin
  :commands which-key-mode
  :hook (after-init . which-key-mode)
  :custom
  (which-key-sort-order #'which-key-key-order-alpha)
  (which-key-idle-delay 1.5)
  (which-key-idle-secondary-delay 0.25)
  (which-key-add-column-padding 1)
  (which-key-max-description-length 40)
  :config
  (which-key-setup-side-window-bottom))

;; Vertico provides a vertical completion interface, making it easier to
;; navigate and select from completion candidates (e.g., when `M-x` is pressed).
(use-package vertico
  ;; (Note: It is recommended to also enable the savehist package.)
  :ensure t
  :general
  (:states 'normal
           "C-."      #'vertico-repeat)
  (:keymaps 'vertico-map
            ;; "M-RET"   #'vertico-exit-input
            "C-j"     #'vertico-next
            ;; "C-M-j"   #'vertico-next-group
            "C-k"     #'vertico-previous
            ;; "C-M-k"   #'vertico-previous-group
            ;; "C-h"     (lambda ()
            ;;             (interactive)
            ;;             (if (eq 'file (vertico--metadata-get 'category))
            ;;                 (vertico-directory-up)))
            ;; "C-l"     (lambda ()
            ;;             (interactive)
            ;;             (if (eq 'file (vertico--metadata-get 'category))
            ;;                 (vertico-insert)))
            ;; "DEL"     #'vertico-directory-delete-char
            )
  :config
  (setq vertico-resize nil
        vertico-count 12
        vertico-cycle t)
  (add-hook 'minibuffer-setup-hook #'vertico-repeat-save)
  (vertico-mode))

(use-package vertico-multiform
  :ensure nil
  :defer t
  :hook (vertico-mode . vertico-multiform-mode)
  :config
  (defvar +vertico-transform-functions nil)

  (cl-defmethod vertico--format-candidate :around
    (cand prefix suffix index start &context ((not +vertico-transform-functions) null))
    (dolist (fun (ensure-list +vertico-transform-functions))
      (setq cand (funcall fun cand)))
    (cl-call-next-method cand prefix suffix index start))

  (defun +vertico-highlight-directory (file)
    "If FILE ends with a slash, highlight it as a directory."
    (when (string-suffix-p "/" file)
      (add-face-text-property 0 (length file) 'marginalia-file-priv-dir 'append file))
    file)

  (defun +vertico-highlight-enabled-mode (cmd)
    "If MODE is enabled, highlight it as font-lock-constant-face."
    (let ((sym (intern cmd)))
      (with-current-buffer (nth 1 (buffer-list))
        (if (or (eq sym major-mode)
                (and
                 (memq sym minor-mode-list)
                 (boundp sym)
                 (symbol-value sym)))
            (add-face-text-property 0 (length cmd) 'font-lock-constant-face 'append cmd)))
      cmd))

  (add-to-list 'vertico-multiform-categories
               '(file
                 (+vertico-transform-functions . +vertico-highlight-directory)))
  (add-to-list 'vertico-multiform-commands
               '(execute-extended-command
                 (+vertico-transform-functions . +vertico-highlight-enabled-mode))))

;; Vertico leverages Orderless' flexible matching capabilities, allowing users
;; to input multiple patterns separated by spaces, which Orderless then
;; matches in any order against the candidates.
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion))))
  (orderless-component-separator #'orderless-escapable-split-on-space))

;; Marginalia allows Embark to offer you preconfigured actions in more contexts.
;; In addition to that, Marginalia also enhances Vertico by adding rich
;; annotations to the completion candidates displayed in Vertico's interface.
(use-package marginalia
  :ensure t
  :commands (marginalia-mode marginalia-cycle)
  :hook (after-init . marginalia-mode)
  :config
  (setq marginalia-align 'right))

;; Embark integrates with Consult and Vertico to provide context-sensitive
;; actions and quick access to commands based on the current selection, further
;; improving user efficiency and workflow within Emacs. Together, they create a
;; cohesive and powerful environment for managing completions and interactions.
(use-package embark
  ;; Embark is an Emacs package that acts like a context menu, allowing
  ;; users to perform context-sensitive actions on selected items
  ;; directly from the completion interface.
  :ensure t
  :commands (embark-act
             embark-dwim
             embark-export
             embark-collect
             embark-bindings
             embark-prefix-help-command)
  :general
  ([remap describe-bindings] #'embark-bindings
   "C-;" #'embark-act)
  (:keymaps  'minibuffer-local-map
             "C-;" #'embark-act
             "M-;" #'embark-dwim
             "C-c C-;" #'embark-export
             "C-c C-l" #'embark-collect)
  (:keymaps 'embark-consult-search-map
            "f" #'consult-fd)
  :init
  (setq prefix-help-command #'embark-prefix-help-command)

  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none))))

  (defun embark-which-key-indicator ()
    "An embark indicator that displays keymaps using which-key.
The which-key help message will show the type and value of the
current target followed by an ellipsis if there are further
targets."
    (lambda (&optional keymap targets prefix)
      (if (null keymap)
          (which-key--hide-popup-ignore-command)
        (which-key--show-keymap
         (if (eq (plist-get (car targets) :type) 'embark-become)
             "Become"
           (format "Act on %s '%s'%s"
                   (plist-get (car targets) :type)
                   (embark--truncate-target (plist-get (car targets) :target))
                   (if (cdr targets) "…" "")))
         (if prefix
             (pcase (lookup-key keymap prefix 'accept-default)
               ((and (pred keymapp) km) km)
               (_ (key-binding prefix 'accept-default)))
           keymap)
         nil nil t (lambda (binding)
                     (not (string-suffix-p "-argument" (cdr binding))))))))

  (setq embark-indicators
        '(embark-which-key-indicator
          embark-highlight-indicator
          embark-isearch-highlight-indicator))

  (defun embark-hide-which-key-indicator (fn &rest args)
    "Hide the which-key indicator immediately when using the completing-read prompter."
    (which-key--hide-popup-ignore-command)
    (let ((embark-indicators
           (remq #'embark-which-key-indicator embark-indicators)))
      (apply fn args)))

  (advice-add #'embark-completing-read-prompter
              :around #'embark-hide-which-key-indicator))

(use-package embark-consult
  :ensure t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;; Consult offers a suite of commands for efficient searching, previewing, and
;; interacting with buffers, file contents, and more, improving various tasks.
(use-package consult
  :ensure t
  :general
  ("C-c C"  'embark-consult-search-map)
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)
         ("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x 5 b" . consult-buffer-other-frame)
         ("C-x t b" . consult-buffer-other-tab)
         ("C-x r b" . consult-bookmark)
         ("C-x p b" . consult-project-buffer)
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o" . consult-outline)
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)
         ("M-s e" . consult-isearch-history)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)
         ("M-r" . consult-history))

  ;; Enable automatic preview at point in the *Completions* buffer.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  :init
  ;; Optionally configure the register formatting. This improves the register
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  (setq-default completion-in-region-function #'consult-completion-in-region)

  ;; Aggressive asynchronous that yield instantaneous results. (suitable for
  ;; high-performance systems.) Note: Minad, the author of Consult, does not
  ;; recommend aggressive values.
  ;; Read: https://github.com/minad/consult/discussions/951
  ;;
  ;; However, the author of minimal-emacs.d uses these parameters to achieve
  ;; immediate feedback from Consult.
  ;; (setq consult-async-input-debounce 0.02
  ;;       consult-async-input-throttle 0.05
  ;;       consult-async-refresh-delay 0.02)

  :config
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))
  (setq consult-narrow-key "<"))


(grep-command "rg -nS --no-heading ")
(setopt xref-search-program 'ripgrep)
(setopt grep-find-ignored-directories
        '("SCCS" "RCS" "CVS" "MCVS" ".src" ".svn" ".git" ".hg" ".bzr" "_MTN" "_darcs" "{arch}" "node_modules" "build" "dist"))
(use-package wgrep
  :ensure t
  :commands wgrep-change-to-wgrep-mode
  :config (setq wgrep-auto-save-buffer t))

(use-package rg
  :defer t)

;; The built-in outline-minor-mode provides structured code folding in modes
;; such as Emacs Lisp and Python, allowing users to collapse and expand sections
;; based on headings or indentation levels. This feature enhances navigation and
;; improves the management of large files with hierarchical structures.
(use-package outline
  :ensure nil
  :commands outline-minor-mode
  :hook
  ((emacs-lisp-mode . outline-minor-mode)
   ;; Use " ▼" instead of the default ellipsis "..." for folded text to make
   ;; folds more visually distinctive and readable.
   (outline-minor-mode
    .
    (lambda()
      (let* ((display-table (or buffer-display-table (make-display-table)))
             (face-offset (* (face-id 'shadow) (ash 1 22)))
             (value (vconcat (mapcar (lambda (c) (+ face-offset c)) " ▼"))))
        (set-display-table-slot display-table 'selective-display value)
        (setq buffer-display-table display-table))))))

;; The outline-indent Emacs package provides a minor mode that enables code
;; folding based on indentation levels.
;;
;; In addition to code folding, *outline-indent* allows:
;; - Moving indented blocks up and down
;; - Indenting/unindenting to adjust indentation levels
;; - Inserting a new line with the same indentation level as the current line
;; - Move backward/forward to the indentation level of the current line
;; - and other features.
(use-package outline-indent
  :ensure t
  :commands outline-indent-minor-mode

  :custom
  (outline-indent-ellipsis " ▼")

  :init
  ;; The minor mode can also be automatically activated for a certain modes.
  (add-hook 'python-mode-hook #'outline-indent-minor-mode)
  (add-hook 'python-ts-mode-hook #'outline-indent-minor-mode)

  (add-hook 'yaml-mode-hook #'outline-indent-minor-mode)
  (add-hook 'yaml-ts-mode-hook #'outline-indent-minor-mode))

;; The stripspace Emacs package provides stripspace-local-mode, a minor mode
;; that automatically removes trailing whitespace and blank lines at the end of
;; the buffer when saving.
(use-package stripspace
  :ensure t
  :commands stripspace-local-mode

  ;; Enable for prog-mode-hook, text-mode-hook, conf-mode-hook
  :hook ((prog-mode . stripspace-local-mode)
         (text-mode . stripspace-local-mode)
         (conf-mode . stripspace-local-mode))

  :custom
  ;; The `stripspace-only-if-initially-clean' option:
  ;; - nil to always delete trailing whitespace.
  ;; - Non-nil to only delete whitespace when the buffer is clean initially.
  ;; (The initial cleanliness check is performed when `stripspace-local-mode'
  ;; is enabled.)
  (stripspace-only-if-initially-clean nil)

  ;; Enabling `stripspace-restore-column' preserves the cursor's column position
  ;; even after stripping spaces. This is useful in scenarios where you add
  ;; extra spaces and then save the file. Although the spaces are removed in the
  ;; saved file, the cursor remains in the same position, ensuring a consistent
  ;; editing experience without affecting cursor placement.
  (stripspace-restore-column t))




(use-package project
  ;; :bind ("M-O" . project-find-file)
  :defer t
  :ensure nil
  :config
  (require 'keymap) ;; keymap-substitute requires emacs version 29.1?
  (require 'cl-seq)

  (keymap-substitute project-prefix-map #'project-find-regexp #'consult-ripgrep)
  (cl-nsubstitute-if
   '(consult-ripgrep "Find regexp")
   (pcase-lambda (`(,cmd _)) (eq cmd #'project-find-regexp))
   project-switch-commands))

(use-package otpp
  :after project
  :init
  ;; Enable `otpp-mode` globally
  (otpp-mode 1)
  ;; If you want to advice the commands in `otpp-override-commands`
  ;; to be run in the current's tab (so, current project's) root directory
  (otpp-override-mode 1))

(use-package transient
  :ensure (transient :branch "main" :host github :repo "magit/transient")
  :defer t
  :config
  (setq transient-mode-line-format nil)
  ;; This causes windows to resize
  ;; (setq transient-display-buffer-action '(display-buffer-below-selected
  ;;                                    (side . bottom)
  ;;                                    (dedicated . t)
  ;;                                    (inhibit-same-window . t)))
  )

(use-package magit
  :ensure (magit :branch "main" :host github :repo "magit/magit" :pre-build ("make" "info"))
  :commands (magit-status magit-file-delete)
  :init
  (setq magit-auto-revert-mode nil)
  :config
  (setq magit-display-buffer-function 'magit-display-buffer-same-window-except-diff-v1)
  ;; (setq magit-refresh-status-buffer nil)
  (setq transient-default-level 5
        magit-diff-refine-hunk t ; show granular diffs in selected hunk
        ;; Don't autosave repo buffers. This is too magical, and saving can
        ;; trigger a bunch of unwanted side-effects, like save hooks and
        ;; formatters. Trust the user to know what they're doing.
        magit-save-repository-buffers nil
        ;; Don't display parent/related refs in commit buffers; they are rarely
        ;; helpful and only add to runtime costs.
        magit-revision-insert-related-refs nil)

  (setq magit-section-visibility-indicator '("..." . t))
  
  (add-hook 'magit-process-mode-hook #'goto-address-mode)

  (define-key magit-mode-map "q" #'+magit/quit)
  (define-key magit-mode-map "Q" #'+magit/quit-all)
  (define-key transient-map [escape] #'transient-quit-one)

  (remove-hook 'server-switch-hook 'magit-commit-diff)
  (remove-hook 'with-editor-filter-visit-hook 'magit-commit-diff)
  (remove-hook 'magit-refs-sections-hook 'magit-insert-tags)

  ;; An optimization that particularly affects macOS and Windows users: by
  ;; resolving `magit-git-executable' Emacs does less work to find the
  ;; executable in your PATH, which is great because it is called so frequently.
  ;; However, absolute paths will break magit in TRAMP/remote projects if the
  ;; git executable isn't in the exact same location.
  (defun +magit-optimize-process-calls-h ()
    "Optimize Magit's process calls by resolving the absolute path of `magit-git-executable'."
    (when-let ((path (executable-find magit-git-executable t)))
      (setq-local magit-git-executable path)))

  (add-hook 'magit-status-mode-hook #'+magit-optimize-process-calls-h))

;; Tree-sitter in Emacs is an incremental parsing system introduced in Emacs 29
;; that provides precise, high-performance syntax highlighting. It supports a
;; broad set of programming languages, including Bash, C, C++, C#, CMake, CSS,
;; Dockerfile, Go, Java, JavaScript, JSON, Python, Rust, TOML, TypeScript, YAML,
;; Elisp, Lua, Markdown, and many others.
(use-package treesit-auto
  :ensure t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; Set the maximum level of syntax highlighting for Tree-sitter modes
(setq treesit-font-lock-level 4)


(use-package rainbow-delimiters
  ;; :ensure nil
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package colorful-mode
  :defer t
  :ensure t
  :hook (emacs-lisp-mode . colorful-mode)
  :custom
  (colorful-use-prefix t)
  (colorful-prefix-alignment 'left)
  (colorful-prefix-string "●"))

(use-package prog-mode
  :ensure nil
  :hook ((emacs-lisp-mode . electric-indent-mode)
         (prog-mode . electric-pair-mode)
         (prog-mode . drag-stuff-mode)
         (prog-mode . dumb-jump-mode)
         ;; (prog-mode . hs-minor-mode)
         (prog-mode . flymake-mode)
         (prog-mode . setup-programming-mode)
         (prog-mode . display-line-numbers-mode)
         (prog-mode . global-prettify-symbols-mode))
  ;; :custom
  ;; ;; (setopt left-fringe 20)
  ;; (set-fringe-style '(32 . 0))
  :config
  (setopt display-line-numbers-type 'relative
          display-line-numbers-widen t
          display-line-numbers-width 3))

(use-package flymake
  :ensure nil
  :defer t
  :hook (prog-mode . flymake-mode)
  ;; :init
  ;; (add-hook 'flymake-mode-hook (lambda () (set-fringe-style '(nil . 4))))
  ;; (add-hook 'flymake-mode (lambda () (fringe-mode '(left-fringe-width . 4))))
  ;; (add-hook 'flymake-mode-hook
  ;;           (lambda ()
  ;;             (set-fringe-style (cons (frame-parameter nil 'left-fringe) 4))))


  ;; A non-descript, left-pointing arrow
  ;; (define-fringe-bitmap 'flymake-fringe-bitmap-double-arrow [16 48 112 240 112 48 16] nil nil 'center)

  ;; (setq flymake-error-bitmap '( flymake-fringe-bitmap-double-arrow modus-themes-prominent-error ))
  ;; (setq flymake-warning-bitmap '( flymake-fringe-bitmap-double-arrow modus-themes-prominent-warning ))
  ;; (setq flymake-note-bitmap '( flymake-fringe-bitmap-double-arrow modus-themes-prominent-note ))

  :config
  ;; (setq flymake-error-bitmap '(flyake-fringe-bitmap-double-arrow flymake-error))
  ;; (setq flymake-warning-bitmap '(flymake-fringe-bitmap-double-arrow flymake-warning))
  ;; (setq flymake-note-bitmap '(flymake-fringe-bitmap-double-arrow flymake-note))
  (setq flymake-show-diagnostics-at-end-of-line 'short)

  ;; (setq flymake-indicator-type fringe) 
  (setq flymake-indicator-type 'fringes) 
  (setq flymake-fringe-indicator-position 'right-fringe)
  )

;; TODO: Angular

(use-package typescript-ts-mode
  :ensure nil
  :defer t
  :mode "\\.ts\\'"
  :config
  (add-to-list 'find-sibling-rules
               '("\\(.+\\)\\.component\\.ts\\'" "\\1.component.html"))
  (add-to-list 'find-sibling-rules
               '("\\(.+\\)\\.ts\\'" "\\1.spec.ts"))
  (add-to-list 'find-sibling-rules
               '("\\(.+\\)\\.container\\.ts\\'" "\\1.container.html"))
  (add-to-list 'find-sibling-rules
               '("\\(.+\\)\\.spec\\.ts\\'" "\\1.ts")))



;; TODO:
;; (use-package js-pkg-mode
;;   :ensure (js-pkg-mode :host "github.com" :repo "https://github.com/ovistoica/js-pkg-mode")
;;   ;; TODO: Defer this
;;   :init (js-pkg-global-mode 1))

;; (use-package fancy-compilation
;;   :commands (fancy-compilation-mode))
;; 
;; (with-eval-after-load 'compile
;;   (fancy-compilation-mode))

(use-package compile
  :defer t
  :ensure nil
  :hook (compilation-mode . visual-line-mode)  ; Enable visual-line-mode in compilation buffers
  :custom
  (compilation-always-kill t)
  (compilation-auto-jump-to-first-error t)
  (compilation-ask-about-save nil)
  (compilation-skip-threshold 1)
  (compilation-scroll-output 'all)
  (compilation-highlight-overlay t)
  (compilation-environment '("TERM=dumb" "TERM=xterm-256color"))
  (compilation-window-height 10)
  (compilation-reuse-window t)
  (compilation-max-output-line-length nil)
  (compilation-error-screen-columns nil)
  (ansi-color-for-compilation-mode t)
  :config
  ;; Add ANSI color filtering
  (add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)
  ;; Auto-close compilation buffer on success after 1 second
  (add-hook 'compilation-finish-functions
            (lambda (buf str)
              (when (string-match "finished" str)
                (run-at-time 1 nil (lambda ()
                                     (delete-windows-on buf)
                                     (bury-buffer buf)))))))

(add-hook 'comint-mode-hook
          (lambda ()
            (setq-local comint-prompt-read-only t)
            (setq-local visual-line-mode t)))

;; TODO: Mine
(use-package dumb-jump
  :defer t
  :config
  (put 'dumb-jump-go 'byte-obsolete-info nil)
  (setq dumb-jump-window 'current
        dumb-jump-quiet t
        xref-show-definitions-function #'xref-show-definitions-completing-read)
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate))

(use-package corfu
  :hook (after-init . global-corfu-mode)
  :general
  (:keymaps 'corfu-mode-map
            ;; :states 'insert
            "C-@" #'completion-at-point
            "C-SPC" #'completion-at-point
            "C-n" #'corfu-next
            "C-p" #'corfu-previous)
  (:keymaps 'corfu-map
            :states 'insert
            "C-SPC" #'corfu-insert-separator
            "C-k" #'corfu-previous
            "C-j" #'corfu-next
            "TAB" #'corfu-next
            "S-TAB" #'corfu-previous
            "C-u" (lambda ()
                    (interactive)
                    (let ((corfu-cycle nil))
                      (call-interactively #'corfu-next (- corfu-count))))
            "C-d" (lambda ()
                    (interactive)
                    (let ((corfu-cycle nil))
                      (call-interactively #'corfu-next corfu-count))))
  :custom
  (read-extended-command-predicate #'command-completion-default-include-p)
  (tab-always-indent 'complete)
  (corfu-right-margin-width 0)
  (corfu-left-margin-width 0)
  :config
  (keymap-unset corfu-map "RET")

  (require 'orderless)

  ;; Orderless fast dispatch for small literals
  (defun orderless-fast-dispatch (word index total)
    (and (= index 0) (= total 1) (length< word 4)
         (cons 'orderless-literal-prefix word)))

  (orderless-define-completion-style orderless-fast
    (orderless-style-dispatchers '(orderless-fast-dispatch))
    (orderless-matching-styles '(orderless-literal orderless-regexp)))

  ;; Configure corfu completion styles and settings
  (setq-local completion-styles '(orderless-fast basic))
  (setq corfu-auto t
        corfu-auto-prefix 1
        corfu-auto-delay 0.1
        corfu-cycle t
        corfu-preselect 'prompt
        corfu-count 16
        corfu-max-width 120
        corfu-quit-at-boundary 'separator
        corfu-quit-no-match corfu-quit-at-boundary
        tab-always-indent 'complete)

  (add-hook 'evil-insert-state-exit-hook #'corfu-quit)

  ;; Minibuffer completion behavior
  (setq global-corfu-minibuffer
        (lambda ()
          (not (or (bound-and-true-p vertico--input)
                   (eq (current-local-map) read-passwd-map))))))

(defvar +corfu-buffer-scanning-size-limit (* 1 1024 1024) ; 1 MB
  "Size limit for a buffer to be scanned by `cape-dabbrev'.")

;; (use-package cape
;;   :ensure t
;;   :defer nil
;;   :config
;;   (defun +corfu-add-cape-file-h ()
;;     (add-hook 'completion-at-point-functions #'cape-file))
;;   (add-hook 'prog-mode-hook #'+corfu-add-cape-file-h)
;;   ;; (defun +corfu-add-cape-elisp-block-h ()
;;   ;;   (add-hook 'completion-at-point-functions #'cape-elisp-block))
;; 
;;   ;; (add-hook 'org-mode-hook #'+corfu-add-cape-elisp-block-h)
;;   ;; (add-hook 'markdown-mode-hook #'+corfu-add-cape-elisp-block-h)
;; 
;;   ;; Enable Dabbrev completion basically everywhere as a fallback.
;;   (setq cape-dabbrev-min-length 1)
;;   (setq cape-dabbrev-check-other-buffers t)
;;   ;; Set up `cape-dabbrev' options.
;;   (defun +dabbrev-friend-buffer-p (other-buffer)
;;     (< (buffer-size other-buffer) +corfu-buffer-scanning-size-limit))
;; 
;;   (defun +corfu-add-cape-dabbrev-h ()
;;     (add-hook 'completion-at-point-functions #'cape-dabbrev))
;; 
;;   (defun add-cape-dabbrev-to-modes ()
;;     (dolist (hook '(prog-mode-hook
;;                     text-mode-hook
;;                     sgml-mode-hook
;;                     conf-mode-hook
;;                     comint-mode-hook
;;                     minibuffer-setup-hook
;;                     eshell-mode-hook))
;;       (add-hook hook #'+corfu-add-cape-dabbrev-h)))
;; 
;;   (add-cape-dabbrev-to-modes)
;; 
;;   (require 'dabbrev)
;;   (setq dabbrev-friend-buffer-function #'+dabbrev-friend-buffer-p
;;         dabbrev-ignored-buffer-regexps
;;         '("\\` "
;;           "\\(?:\\(?:[EG]?\\|GR\\)TAGS\\|e?tags\\|GPATH\\)\\(<[0-9]+>\\)?")
;;         dabbrev-upcase-means-case-search t)
;;   (add-to-list 'dabbrev-ignored-buffer-modes 'pdf-view-mode)
;;   (add-to-list 'dabbrev-ignored-buffer-modes 'doc-view-mode)
;;   (add-to-list 'dabbrev-ignored-buffer-modes 'tags-table-mode)
;; 
;;   ;; Make these capfs composable.
;;   (advice-add #'comint-completion-at-point :around #'cape-wrap-nonexclusive)
;;   (advice-add #'eglot-completion-at-point :around #'cape-wrap-nonexclusive)
;;   (advice-add #'pcomplete-completions-at-point :around #'cape-wrap-nonexclusive))

(use-package corfu-history
  :ensure nil
  :hook (corfu-mode . corfu-history-mode)
  :config
  (require 'savehist)
  (add-to-list 'savehist-additional-variables 'corfu-history))

;; TODO: Elisp?
(use-package corfu-popupinfo
  :ensure nil
  :hook (corfu-mode . corfu-popupinfo-mode)
  :general
  (:keymaps 'corfu-popupinfo-map
            "C-h"      #'corfu-popupinfo-toggle
            "C-S-k"    #'corfu-popupinfo-scroll-down
            "C-S-j"    #'corfu-popupinfo-scroll-up
            "C-<up>"   #'corfu-popupinfo-scroll-down
            "C-<down>" #'corfu-popupinfo-scroll-up
            "C-S-p"    #'corfu-popupinfo-scroll-down
            "C-S-n"    #'corfu-popupinfo-scroll-up
            "C-S-u"    #'corfu-popupinfo-scroll-up
            "C-S-d"    #'corfu-popupinfo-scroll-down)
  :config
  (setq corfu-popupinfo-delay '(0.5 . 1.0)))

;; The markdown-mode package provides a major mode for Emacs for syntax
;; highlighting, editing commands, and preview support for Markdown documents.
;; It supports core Markdown syntax as well as extensions like GitHub Flavored
;; Markdown (GFM).
(use-package markdown-mode
  :commands (gfm-mode
             gfm-view-mode
             markdown-mode
             markdown-view-mode)
  :mode (("\\.markdown\\'" . markdown-mode)
         ("\\.md\\'" . markdown-mode)
         ("README\\.md\\'" . gfm-mode))
  :bind
  (:map markdown-mode-map
        ("C-c C-e" . markdown-do)))

;; Highlights function and variable definitions in Emacs Lisp mode
(use-package highlight-defined
  :ensure t
  :commands highlight-defined-mode
  :hook
  (emacs-lisp-mode . highlight-defined-mode))


(use-package indent-bars
  :defer t
  :vc (indent-bars
       :url "https://github.com/jdtsmith/indent-bars"
       :branch "main"
       :rev :newest)
  :hook (prog-mode . indent-bars-mode)
  :custom
  (indent-bars-starting-column 0)
  (indent-bars-pad-frac 0.4)
  (indent-bars-color '(highlight :face-bg t :blend 0.15))
  (indent-bars-highlight-current-depth '(:blend 0.5)) ; pump up the BG blend on current
  (indent-bars-treesit-support t)
  (indent-bars-treesit-ignore-blank-lines-types '("comment")) ; Ignore comments
  (indent-bars-width-frac 0.1)
  (indent-bars-pattern ".")
  ;; (indent-bars-prefer-character t)
  :config
  (add-hook 'indent-bars-mode (lambda () (advice-add 'line-move-to-column :around
                                                (defun my/indent-bars-prevent-passing-newline (orig col &rest r)
                                                  (if-let ((indent-bars-mode)
    	                                                   (nlp (line-end-position))
    	                                                   (dprop (get-text-property nlp 'display))
    	                                                   ((seq-contains-p dprop ?\n))
    	                                                   ((> col (- nlp (point)))))
                                                      (goto-char nlp)
                                                    (apply orig col r)))))))

(use-package ligature
  :hook (prog-mode . global-ligature-mode)
  :config
  ;; Enable all Cascadia Code ligatures in programming modes
  ;; (ligature-set-ligatures 'prog-mode '("--" "---" "==" "===" "!=" "!==" "=!="
  ;;                                      "=:=" "=/=" "<=" ">=" "&&" "&&&" "&=" "++" "+++" "***" ";;" "!!"
  ;;                                      "??" "???" "?:" "?." "?=" "<:" ":<" ":>" ">:" "<:<" "<>" "<<<" ">>>"
  ;;                                      "<<" ">>" "||" "-|" "_|_" "|-" "||-" "|=" "||=" "##" "###" "####"
  ;;                                      "#{" "#[" "]#" "#(" "#?" "#_" "#_(" "#:" "#!" "#=" "^=" "<$>" "<$"
  ;;                                      "$>" "<+>" "<+" "+>" "<*>" "<*" "*>" "</" "</>" "/>" "<!--" "<#--"
  ;;                                      "-->" "->" "->>" "<<-" "<-" "<=<" "=<<" "<<=" "<==" "<=>" "<==>"
  ;;                                      "==>" "=>" "=>>" ">=>" ">>=" ">>-" ">-" "-<" "-<<" ">->" "<-<" "<-|"
  ;;                                      "<=|" "|=>" "|->" "<->" "<~~" "<~" "<~>" "~~" "~~>" "~>" "~-" "-~"
  ;;                                      "~@" "[||]" "|]" "[|" "|}" "{|" "[<" ">]" "|>" "<|" "||>" "<||"
  ;;                                      "|||>" "<|||" "<|>" "..." ".." ".=" "..<" ".?" "::" ":::" ":=" "::="
  ;;                                      ":?" ":?>" "//" "///" "/*" "*/" "/=" "//=" "/==" "@_" "__" "???"
  ;;                                      "<:<" ";;;"))
  (ligature-set-ligatures '(prog-mode sgml-mode) '(".." ".=" "..." "..<" "::" ":::"
                                                   ":=" "::=" ";;" ";;;" "??" "???"
                                                   ".?" "?." ":?" "?:" "**" "***"
                                                   "/*" "*/" "/**"
                                                   "<-" "->" "-<" ">-" "<--" "-->"
                                                   "<<-" "->>" "-<<" ">>-" "<-<"
                                                   ">->" "<-|" "|->" "-|" "|-" "||-"
                                                   "<!--" "<#--" "<=" "=>" ">="
                                                   "<==" "==>" "<<=" "=>>" "=<<"
                                                   ">>=" "<=<" ">=>" "<=|" "|=>"
                                                   "<=>" "<==>" "||=" "|=" "//="
                                                   "/=" "/=="
                                                   "<<" ">>" "<<<" ">>>" "<>" "<$" "$>"
                                                   "<$>" "<+" "+>" "<+>" "<:" ":<"
                                                   "<:<" ">:" ":>" "<~" "~>" "<~>"
                                                   "<<~" "<~~" "~~>" "~~" "<|" "|>"
                                                   "<|>" "<||" "||>" "<|||"
                                                   "|||>" "</" "/>" "</>" "<*" "*>"
                                                   "<*>" ":?>"
                                                   "#(" "#{" "#[" "]#" "#!" "#?" "#=" "#_"
                                                   "#_(" "##" "###" "####"
                                                   "[|" "|]" "[<" ">]" "{!!" "!!}" "{|"
                                                   "|}" "{{" "}}" "{{--" "--}}"
                                                   "{!--" "//" "///" "!!"
                                                   "www" "@_" "&&" "&&&" "&=" "~@" "++"
                                                   "+++" " \\" " /" "_|_" "||"
                                                   "=:" "=:=" "=!=" "==" "===" "=/="
                                                   "=~" "~-" "^=" "__" "!=" "!==" "-~"
                                                   "--" "---"
                                                   "++" "--" "/=" "&&" "||" "||="
                                                   "<=" ">=" "<=>"
                                                   "/\\" "\\/" "-|" "_|_" "|-" "|="
                                                   "||-" "||="
                                                   "->" "=>" "::" "__"
                                                   "==" "===" "!=" "=/=" "!=="
                                                   "<<" "<<<" "<<=" ">>" ">>>"
                                                   ">>=" "|=" "^="
                                                   "/*" "*/" "/**" "//" "///"
                                                   ":>" ":<" ">:" "::=" "#!"
                                                   "{|" "|}" "#[" "]#"
                                                   "##" "###" "####"
                                                   "--" "---"
                                                   "</" "<!--" "</>" "-->"
                                                   "/>" "www"
                                                   "**" "===" "!==" "?."
                                                   ":="
                                                   "<>" "<~>"
                                                   "?." "??"
                                                   "=!=" "=:=" ":::" "<:<"
                                                   "=>>" "=<<" ">=>" "<=<"
                                                   "<$" "<$>" "$>" "<+" "<+>"
                                                   "+>" "<*" "<*>" "*>" "<>" ".="
                                                   "<|>" "#=" "++" "+++"
                                                   "..<"
                                                   ".." "..." "=~" "!~" "<=>"
                                                   "<|||" "<||" "<|" "|>" "%%"
                                                   "||>" "|||>" "<=" "[|" "|]"
                                                   "~-" "~~"
                                                   "!!"
                                                   ":::"
                                                   "#{" "#(" "#_" "#_(" "#?" "#:"
                                                   ";;" "~@"
                                                   "<-" "->" "#{}" "|>" "<>")))
