;;; emacs-jp-langs.el --- Language modes and related -*- lexical-binding: t; -*-

;;; Commentary:

;; Tabs/indentation, minor modes for programming, Eglot, Denote and
;; focus-mode helpers (logos, olivetti).

;;; Code:

;;;; Tabs, indentation, and the TAB key
(setq tab-always-indent 'complete)
(setq tab-first-completion 'word-or-paren-or-punct) ; Emacs 27
(setq-default tab-width 4
              indent-tabs-mode nil)

;;;; Emacs Lisp major mode
(with-eval-after-load 'elisp-mode
  (keymap-set emacs-lisp-mode-map "C-c C-b" nil) ; I do not want to byte compile the buffer
  (keymap-set emacs-lisp-mode-map "C-c C-f" nil) ; .. nor the file
  (keymap-set lisp-interaction-mode-map "C-c C-b" nil)
  (keymap-set lisp-interaction-mode-map "C-c C-f" nil)

  ;; All of these are from Emacs 31.
  (setq elisp-eldoc-funcall-with-docstring-length 'short)
  (setq elisp-eldoc-docstring-length-limit 1000)
  (set-default-toplevel-value 'lexical-binding t) ; Emacs 31

  (dolist (package jp-emacs-my-packages)
    (add-to-list 'elisp-flymake-byte-compile-load-path (expand-file-name (format "%s" package) "/home/jp/Git/Projects/")))

  (require 'jp-elisp)

  (keymap-set emacs-lisp-mode-map "C-j" #'jp-elisp-eval-and-print-last-sexp)  ; overrides `electric-newline-and-maybe-indent'
  (keymap-set emacs-lisp-mode-map "C-c C-p" #'jp-elisp-pp-macroexpand-last-sexp)
  (keymap-set lisp-interaction-mode-map "C-j" #'jp-elisp-eval-and-print-last-sexp) ; overrides `eval-print-last-sexp'
  (keymap-set lisp-interaction-mode-map "C-c C-p" #'jp-elisp-pp-macroexpand-last-sexp))

;;;; Disable "electric" behaviour
(add-hook 'prog-mode-hook #'electric-indent-local-mode)
(with-eval-after-load 'electric
  ;; I don't like auto indents in Org and related.  They are okay for
  ;; programming.
  (electric-pair-mode -1)
  (electric-quote-mode -1)
  (electric-indent-mode -1))

;;;; Parentheses (show-paren-mode)
(add-hook 'prog-mode-hook #'show-paren-local-mode)
(with-eval-after-load 'paren
  (setq show-paren-style 'parenthesis)
  (setq show-paren-when-point-in-periphery nil)
  (setq show-paren-when-point-inside-paren nil)
  (setq show-paren-context-when-offscreen 'overlay)) ; Emacs 29

;;;; Plain text (text-mode)
(add-to-list 'auto-mode-alist '("\\`\\(README\\|CHANGELOG\\|COPYING\\|LICENSE\\)\\'" . text-mode))

(add-hook 'text-mode-hook #'turn-on-auto-fill)
(add-hook 'prog-mode-hook (lambda () (setq-local sentence-end-double-space t)))

(with-eval-after-load 'text-mode
  (setq sentence-end-double-space nil)
  (setq sentence-end-without-period nil)
  (setq colon-double-space nil)
  (setq use-hard-newlines nil)
  (setq adaptive-fill-mode t))

;; Arch Linux and AUR package scripts (sh-mode)
(add-to-list 'auto-mode-alist '("PKGBUILD" . sh-mode))
;; SystemD and other configuration files (conf-mode)
(add-to-list 'auto-mode-alist '("\\`dircolors\\'" "\\.\\(service\\|timer\\)\\'" "dunstrc"))

;;;; Eldoc (Emacs live documentation feedback)
(add-hook 'prog-mode-hook #'eldoc-mode)
(setq eldoc-idle-delay 1.0)
(setq eldoc-message-function #'message) ; don't use mode line for M-x eval-expression, etc.

;;;; Eglot (built-in client for the language server protocol)
(setq eglot-sync-connect nil)
(setq eglot-autoshutdown t)

;;;; Handle performance for very long lines (so-long.el)
(global-so-long-mode 1)

;;;; Markdown (markdown-mode)
;; Deferred: only loads when a Markdown file is opened.
(use-package markdown-mode
  :defer t
  :config
  (setq markdown-fontify-code-blocks-natively t))

;;;; csv-mode
(use-package csv-mode
  :defer t)

;;;; Flyspell and jp-spell.el (spell check)
(require 'jp-spell)

(keymap-global-set "M-$" #'jp-spell-spell-dwim)
(keymap-global-set "C-M-$" #'jp-spell-change-dictionary)
(keymap-global-set "M-i" #'jp-spell-spell-dwim) ; override `tab-to-tab-stop'
(keymap-global-set "C-M-i" #'jp-spell-change-dictionary) ; override `complete-symbol'

(with-eval-after-load 'flyspell
  (define-key flyspell-mode-map (kbd "C-;") nil)
  (define-key flyspell-mouse-map (kbd "<mouse-3>") #'flyspell-correct-word)
  (define-key ctl-x-x-map (kbd "s") #'flyspell-mode) ; C-x x s

  (setq flyspell-issue-message-flag nil)
  (setq flyspell-issue-welcome-flag nil)
  (setq ispell-program-name "aspell")
  (setq ispell-dictionary "en_GB")

  (setq jp-spell-dictionaries
        '(("EN English" . "en")
          ("EL Ελληνικά" . "el")
          ("FR Français" . "fr")
          ("ES Espanõl" . "es")))

  ;; Also check jp-spell.el for what I am doing with
  ;; `jp-spell-ispell-display-buffer'.
  (setq ispell-choices-buffer "*ispell-top-choices*"))

;;;; Flymake
(defvar jp/flymake-mode-projects-path
  (file-name-as-directory (expand-file-name "Projects" "~/Git/"))
  "Path to my Git projects.")

(defun jp/flymake-mode-lexical-binding ()
  (when lexical-binding
    (flymake-mode 1)))

(defun jp/flymake-mode-in-my-projects ()
  (when-let* ((file (buffer-file-name))
              ((string-prefix-p jp/flymake-mode-projects-path (expand-file-name file)))
              ((not (file-directory-p file)))
              ((file-regular-p file)))
    (add-hook 'find-file-hook #'jp/flymake-mode-lexical-binding nil t)))

(add-hook 'emacs-lisp-mode-hook #'jp/flymake-mode-in-my-projects)

(define-key ctl-x-x-map (kbd "m") #'flymake-mode) ; C-x x m

(with-eval-after-load 'flymake
  (keymap-set flymake-mode-map "C-c ! s" #'flymake-start)
  (keymap-set flymake-mode-map "C-c ! d" #'flymake-show-buffer-diagnostics) ; Emacs28
  (keymap-set flymake-mode-map "C-c ! D" #'flymake-show-project-diagnostics) ; Emacs28
  (keymap-set flymake-mode-map "C-c ! n" #'flymake-goto-next-error)
  (keymap-set flymake-mode-map "C-c ! p" #'flymake-goto-prev-error)

  (setq flymake-fringe-indicator-position 'left-fringe)
  (setq flymake-suppress-zero-counters t)
  (setq flymake-no-changes-timeout nil)
  (setq flymake-start-on-flymake-mode t)
  (setq flymake-start-on-save-buffer t)
  (setq flymake-proc-compilation-prevents-syntax-check t)
  (setq flymake-wrap-around nil)
  (setq flymake-mode-line-format
        '("" flymake-mode-line-exception flymake-mode-line-counters))
  ;; NOTE: `jp-modeline.el' actually defines the counters itself.
  (setq flymake-mode-line-counter-format
        '("" flymake-mode-line-error-counter
          flymake-mode-line-warning-counter
          flymake-mode-line-note-counter ""))
  (setq flymake-show-diagnostics-at-end-of-line nil)) ; Emacs 31

;;; Elisp packaging requirements
(use-package package-lint-flymake
  :config
  (package-lint-flymake-setup))

;;;; `outline' (`outline-mode' and `outline-minor-mode')
(define-key global-map (kbd "<f10>") #'outline-minor-mode)
(setq outline-minor-mode-highlight nil) ; emacs28
(setq outline-minor-mode-cycle t) ; emacs28
(setq outline-minor-mode-use-buttons nil) ; emacs29
(setq outline-minor-mode-use-margins nil) ; as above

;;;; `dictionary'
(define-key global-map (kbd "C-c d") #'dictionary-search)
(setq dictionary-server "dict.org")
(setq dictionary-default-popup-strategy "lev")
(setq dictionary-create-buttons nil)
(setq dictionary-use-single-buffer t)

;;;; Denote (simple note-taking and file-naming)
;; Read the manual: <https://protesilaos.com/emacs/denote>.
(use-package denote
  :config
  (defun jp-denote-dired ()
    (interactive)
    (denote-sort-dired "\\.org$" 'identifier t nil))

  (add-hook 'text-mode-hook #'denote-fontify-links-mode)
  (add-hook 'dired-mode-hook #'denote-dired-mode)

  (keymap-global-set "C-c n n" #'denote)
  (keymap-global-set "C-c n N" #'denote-type)
  (keymap-global-set "C-c n d" #'jp-denote-dired)
  (keymap-global-set "C-c n g" #'denote-grep)
  (keymap-global-set "C-c n r" #'denote-rename-file)

  (with-eval-after-load 'text-mode
    (keymap-set text-mode-map "C-c n i" #'denote-link) ; "insert" mnemonic
    (keymap-set text-mode-map "C-c n I" #'denote-add-links)
    (keymap-set text-mode-map "C-c n b" #'denote-backlinks)
    (keymap-set text-mode-map "C-c n R" #'denote-rename-file-using-front-matter))

  (with-eval-after-load 'dired
    (keymap-set dired-mode-map "C-c C-d C-i" #'denote-dired-link-marked-notes)
    (keymap-set dired-mode-map "C-c C-d C-r" #'denote-dired-rename-marked-files)
    (keymap-set dired-mode-map "C-c C-d C-k" #'denote-dired-rename-marked-files-with-keywords)
    (keymap-set dired-mode-map "C-c C-d C-f" #'denote-dired-rename-marked-files-using-front-matter))

  (with-eval-after-load 'denote
    (setq denote-directory (expand-file-name "~/Documents/Emacs/notes/"))
    (setq denote-file-type 'org) ; Org is the default file type

    (setq denote-title-history nil)
    (setq denote-sort-keywords nil)
    (setq denote-known-keywords '("estudio" "trabajo" "emacs" "linux"))
    (setq denote-files-matching-regexp-history nil)
    (setq denote-history-completion-in-prompts nil)
    (setq denote-infer-keywords t)
    (setq denote-org-front-matter
          "# -*- jinx-languages: \"es_MX\"; -*-
#+title: %s
#+date: %s
#+filetags: %s
#+identifier: %s
#+author: Ing. Javier Pacheco
#+startup: showall\n
\n\n")
    (setq denote-query-links-display-buffer-action
          '((display-buffer-same-window)))
    (setq denote-link--prepare-links-format "%s\n")

    (setq denote-excluded-directories-regexp nil)
    (setq denote-date-format nil)
    (setq denote-rename-confirmations nil) ; CAREFUL with this!
    (setq denote-backlinks-show-context nil)
    (setq denote-buffer-name-prefix "[D] ")
    (setq denote-rename-buffer-format "%D")

    (denote-rename-buffer-mode 1)
    (defun jp/denote-rename-all-to-reorder-components ()
      "Call `denote-dired-rename-files' without any prompts."
      (interactive)
      (let ((denote-prompts nil))
        (call-interactively 'denote-dired-rename-files)))))

;;;; Integrate Consult with Denote
(when jp-emacs-completion-extras
  (use-package consult-denote
    :config
    (keymap-global-set "C-c n f" #'consult-denote-find)
    (keymap-global-set "C-c n g" #'consult-denote-grep)
    (consult-denote-mode 1)))

;;;; Denote Org extras (denote-org)
(use-package denote-org)

;;;; Denote Sequence notes or folgezettel (denote-sequence)
(use-package denote-sequence
  :config
  (require 'denote-sequence)
  (keymap-global-set "C-c n s s" #'denote-sequence)
  (keymap-global-set "C-c n s f" #'denote-sequence-find)
  (keymap-global-set "C-c n s l" #'denote-sequence-link)
  (keymap-global-set "C-c n s d" #'denote-sequence-dired)
  (keymap-global-set "C-c n s r" #'denote-sequence-reparent)
  (keymap-global-set "C-c n s c" #'denote-sequence-convert)
  (setq denote-sequence-scheme 'alphanumeric))

(defun denote-sequence-dired (&optional prefix depth)
  "Produce a Dired listing of all sequence notes.
Sort sequences from smallest to largest.

With optional PREFIX string, show only files whose sequence matches it.

With optional DEPTH as a number, limit the list to files whose sequence
is that many levels deep.  For example, 1=1=2 is three levels deep.

For a more specialised case, see `denote-sequence-find-relatives-dired'."
  (interactive (denote-sequence--get-interactive-for-prefix-and-depth))
  (let* ((roots (seq-filter #'file-directory-p (denote-directories)))
         (single-dir-p (null (cdr roots)))
         (files-fn
          (lambda ()
            (let* ((files (if (and prefix (not (string-blank-p prefix)))
                              (denote-sequence-get-all-files-with-prefix prefix)
                            (denote-sequence-get-all-files)))
                   (files (if depth
                              (denote-sequence-get-all-files-with-max-depth depth files)
                            files))
                   (files (mapcar #'expand-file-name files))
                   (files (seq-filter #'file-exists-p files))
                   (files (denote-sequence-sort-files files)))
              (if single-dir-p
                  (mapcar (lambda (f)
                            (file-relative-name f (car roots)))
                          files)
                files)))))
    (unless roots
      (user-error "No valid Denote directories found"))
    (dlet ((ls-lisp-use-insert-directory-program
            (progn (require 'ls-lisp) nil)))
      (if-let* ((directory (if single-dir-p
                               (car roots)
                             (denote-directories-get-common-root))))
          (progn
            (unless (file-directory-p directory)
              (user-error "Denote root is not a valid directory: %s" directory))
            (if-let* ((files (funcall files-fn))
                      (buffer-name
                       (denote-format-buffer-name
                        (format-message
                         "prefix `%s'; depth `%s'"
                         (or prefix "ALL")
                         (or depth "ALL"))
                        :is-special-buffer))
                      (dired-buffer (dired (cons directory files))))
                (with-current-buffer dired-buffer
                  (rename-buffer buffer-name :unique)
                  (setq-local revert-buffer-function
                              (lambda (&rest _)
                                (dlet ((ls-lisp-use-insert-directory-program
                                        (progn (require 'ls-lisp) nil)))
                                  (if-let* ((files (funcall files-fn)))
                                      (progn
                                        (setq-local dired-directory
                                                    (cons directory files))
                                        (dired-revert))
                                    (denote-dired-empty-mode))))))
              (message "No matching files")))
        (user-error "Unable to determine Denote root directory")))))

;;;; Custom extensions for "focus mode" (logos.el)
;; Read the manual: <https://protesilaos.com/emacs/logos>.
(use-package olivetti
  :config
  (setq-default olivetti-body-width 0.7)
  (setq olivetti-minimum-body-width 80)
  (setq olivetti-recall-visual-line-mode-entry-state t))

(use-package logos
  :config
  (keymap-global-set "C-x n n" #'logos-narrow-dwim)
  (keymap-global-set "C-x ]" #'logos-forward-page-dwim)
  (keymap-global-set "C-x [" #'logos-backward-page-dwim)
  (keymap-global-set "M-]" #'logos-forward-page-dwim)
  (keymap-global-set "M-[" #'logos-backward-page-dwim)
  (keymap-global-set "M-n" #'logos-forward-page-dwim)
  (keymap-global-set "M-p" #'logos-backward-page-dwim)
  (keymap-global-set "<f9>" #'logos-focus-mode)

  (with-eval-after-load 'logos
    (setq logos-outlines-are-pages t)
    (setq logos-outline-regexp-alist
          `((emacs-lisp-mode . ,(format "\\(^;;;+ \\|%s\\)" logos-page-delimiter))
            (org-mode . ,(format "\\(^\\*+ +\\|^-\\{5\\}$\\|%s\\)" logos-page-delimiter))
            (markdown-mode . ,(format "\\(^\\#+ +\\|^[*-]\\{5\\}$\\|^\\* \\* \\*$\\|%s\\)" logos-page-delimiter))
            (conf-toml-mode . "^\\[")))

    ;; These apply when `logos-focus-mode' is enabled.  Their value is
    ;; buffer-local.
    (setq-default logos-hide-mode-line t)
    (setq-default logos-hide-header-line t)
    (setq-default logos-hide-buffer-boundaries t)
    (setq-default logos-hide-fringe t)
    (setq-default logos-variable-pitch t)
    (setq-default logos-buffer-read-only nil)
    (setq-default logos-scroll-lock nil)
    (setq-default logos-olivetti t)

    (add-hook 'enable-theme-functions #'logos-update-fringe-in-buffers)

    ;;;; Extra tweaks
    ;; place point at the top when changing pages, but not in `prog-mode'
    (defun jp/logos-recenter-top ()
      "Use `recenter' to reposition the view at the top."
      (unless (derived-mode-p 'prog-mode)
        (recenter 1))) ; Use 0 for the absolute top

    (add-hook 'logos-page-motion-hook #'jp/logos-recenter-top)))

(use-package buffer-to-pdf
  :config
  (setq buffer-to-pdf-directory (expand-file-name "/tmp/pdf")))

(provide 'emacs-jp-langs)

;;; emacs-jp-langs.el ends here
