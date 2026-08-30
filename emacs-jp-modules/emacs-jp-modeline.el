;;; emacs-jp-modeline.el --- Mode line (jp-modeline) -*- lexical-binding: t; -*-

;;; Commentary:

;; Custom mode line built on the jp-modeline library (my own), with
;; theme-aware indicator faces, `which-function' and Keycast.

;;; Code:

;;; Mode line
(require 'jp-modeline)
(setq mode-line-compact nil) ; Emacs 28
(setq mode-line-right-align-edge 'right-margin) ; Emacs 30
(setq jp-modeline-show-frame-name (alist-get 'undecorated initial-frame-alist))

;; `modus-themes' provides the `modus-themes-with-colors' macro used to
;; theme the indicator faces below (this also serves the `ef' family in
;; the `(memq ... '(modus ef standard))' branch).  It must be loaded so
;; the macro is defined when `jp/modeline-set-faces' is evaluated.
(use-package modus-themes)

(setq-default mode-line-format
              '("%e"
                (:eval (when (bound-and-true-p evil-mode)
                         evil-mode-line-tag))
                jp-modeline-narrow
                jp-modeline-buffer-status
                jp-modeline-window-dedicated-status
                jp-modeline-input-method
                "  "
                jp-modeline-buffer-identification
                "  "
                jp-modeline-major-mode
                jp-modeline-process
                "  "
                jp-modeline-frame-name
                "  "
                jp-modeline-vc-branch
                "  "
                jp-modeline-eglot
                "  "
                jp-modeline-flymake
                "  "
                mode-line-format-right-align ; Emacs 30
                jp-modeline-which-function-indicator
                jp-modeline-notmuch-indicator
                "  "
                jp-modeline-misc-info
                jp-modeline-kbd-macro))

(when jp-emacs-load-theme-family
  (cond
   ((memq jp-emacs-load-theme-family '(modus ef standard))
    (defun jp/modeline-set-faces ()
      (modus-themes-with-colors
        (custom-set-faces
         `(jp-modeline-indicator-red ((,c :inherit bold :foreground ,red)))
         `(jp-modeline-indicator-green ((,c :inherit bold :foreground ,green)))
         `(jp-modeline-indicator-yellow ((,c :inherit bold :foreground ,yellow)))
         `(jp-modeline-indicator-blue ((,c :inherit bold :foreground ,blue)))
         `(jp-modeline-indicator-magenta ((,c :inherit bold :foreground ,magenta)))
         `(jp-modeline-indicator-cyan ((,c :inherit bold :foreground ,cyan)))
         `(jp-modeline-indicator-red-bg ((,c :inherit (bold jp-modeline-indicator-button) :background ,bg-red-intense :foreground ,fg-main)))
         `(jp-modeline-indicator-green-bg ((,c :inherit (bold jp-modeline-indicator-button) :background ,bg-green-intense :foreground ,fg-main)))
         `(jp-modeline-indicator-yellow-bg ((,c :inherit (bold jp-modeline-indicator-button) :background ,bg-yellow-intense :foreground ,fg-main)))
         `(jp-modeline-indicator-blue-bg ((,c :inherit (bold jp-modeline-indicator-button) :background ,bg-blue-intense :foreground ,fg-main)))
         `(jp-modeline-indicator-magenta-bg ((,c :inherit (bold jp-modeline-indicator-button) :background ,bg-magenta-intense :foreground ,fg-main)))
         `(jp-modeline-indicator-cyan-bg ((,c :inherit (bold jp-modeline-indicator-button) :background ,bg-cyan-intense :foreground ,fg-main))))))
    (add-hook 'modus-themes-after-load-theme-hook #'jp/modeline-set-faces))
   ((eq jp-emacs-load-theme-family 'doric)
    (defun jp/modeline-set-faces ()
      (doric-themes-with-colors
        (custom-set-faces
         `(jp-modeline-indicator-red ((t :inherit bold :foreground ,fg-red)))
         `(jp-modeline-indicator-green ((t :inherit bold :foreground ,fg-green)))
         `(jp-modeline-indicator-yellow ((t :inherit bold :foreground ,fg-yellow)))
         `(jp-modeline-indicator-blue ((t :inherit bold :foreground ,fg-blue)))
         `(jp-modeline-indicator-magenta ((t :inherit bold :foreground ,fg-magenta)))
         `(jp-modeline-indicator-cyan ((t :inherit bold :foreground ,fg-cyan)))
         `(jp-modeline-indicator-red-bg ((t :inherit (bold jp-modeline-indicator-button) :background ,bg-red :foreground ,fg-main)))
         `(jp-modeline-indicator-green-bg ((t :inherit (bold jp-modeline-indicator-button) :background ,bg-green :foreground ,fg-main)))
         `(jp-modeline-indicator-yellow-bg ((t :inherit (bold jp-modeline-indicator-button) :background ,bg-yellow :foreground ,fg-main)))
         `(jp-modeline-indicator-blue-bg ((t :inherit (bold jp-modeline-indicator-button) :background ,bg-blue :foreground ,fg-main)))
         `(jp-modeline-indicator-magenta-bg ((t :inherit (bold jp-modeline-indicator-button) :background ,bg-magenta :foreground ,fg-main)))
         `(jp-modeline-indicator-cyan-bg ((t :inherit (bold jp-modeline-indicator-button) :background ,bg-cyan :foreground ,fg-main))))))
    (add-hook 'doric-themes-after-load-theme-hook #'jp/modeline-set-faces)))

  (jp/modeline-set-faces))

(with-eval-after-load 'spacious-padding
  (defun jp/modeline-spacious-indicators ()
    "Set box attribute to `'jp-modeline-indicator-button' if spacious-padding is enabled."
    (if (bound-and-true-p spacious-padding-mode)
        (set-face-attribute 'jp-modeline-indicator-button nil :box '(:style flat-button))
      (set-face-attribute 'jp-modeline-indicator-button nil :box 'unspecified)))

  ;; Run it at startup and then afterwards whenever
  ;; `spacious-padding-mode' is toggled on/off.
  (jp/modeline-spacious-indicators)

  (add-hook 'spacious-padding-mode-hook #'jp/modeline-spacious-indicators))

;;; Show the name of the current definition or heading (`which-function-mode')
(setq which-func-modes '(prog-mode org-mode))
;; The indicator is handled on my own via `jp-modeline-which-function-indicator'.
(setq which-func-display 'mode) ; Emacs 30
(setq which-func-unknown "")

(with-eval-after-load 'jp-modeline
  (defun jp/which-function ()
    "A more opinionated `which-function'."
    (let ((name nil))
      (cond
       ((derived-mode-p 'lisp-data-mode)
        (ignore-errors
          (when-let* ((text (save-excursion
                              (beginning-of-defun)
                              (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
                      (definition (replace-regexp-in-string "(.+?\s+\\(.*\\)" "\\1" text)))
            (setq name (if (string-prefix-p ";" definition)
                           ""
                         (jp-modeline-string-abbreviate-but-last definition 1))))))
       (t
        (when (null name)
          (setq name (add-log-current-defun)))
        ;; If Imenu is loaded, try to make an index alist with it.
        (when (and (null name)
                   (null add-log-current-defun-function))
          (when (and (null name)
                     (boundp 'imenu--index-alist)
                     (or (null imenu--index-alist)
                         ;; Update if outdated
                         (/= (buffer-chars-modified-tick) imenu-menubar-modified-tick))
                     (null which-function-imenu-failed))
            (ignore-errors (imenu--make-index-alist t))
            (unless imenu--index-alist
              (setq-local which-function-imenu-failed t)))
          ;; If we have an index alist, use it.
          (when (and (null name)
                     (boundp 'imenu--index-alist) imenu--index-alist)
            (let ((alist imenu--index-alist)
                  (minoffset (point-max))
                  offset pair mark imstack namestack)
              ;; Elements of alist are either ("name" . marker), or
              ;; ("submenu" ("name" . marker) ... ). The list can be
              ;; arbitrarily nested.
              (while (or alist imstack)
                (if (null alist)
                    (setq alist     (car imstack)
                          namestack (cdr namestack)
                          imstack   (cdr imstack))
                  (setq pair (car-safe alist)
                        alist (cdr-safe alist))
                  (cond
                   ((atom pair))            ; Skip anything not a cons.

                   ((imenu--subalist-p pair)
                    (setq imstack   (cons alist imstack)
                          namestack (cons (car pair) namestack)
                          alist     (cdr pair)))

                   ((or (number-or-marker-p (setq mark (cdr pair)))
                        (and (overlayp mark)
                             (setq mark (overlay-start mark))))
                    (when (and (>= (setq offset (- (point) mark)) 0)
                               (< offset minoffset)) ; Find the closest item.
                      (setq minoffset offset
                            name (if (null which-func-imenu-joiner-function)
                                     (car pair)
                                   (funcall
                                    which-func-imenu-joiner-function
                                    (reverse (cons (car pair) namestack)))))))))))))
        (jp-modeline-string-cut-end name)))))

  (advice-add #'which-function :override #'jp/which-function)

  (which-function-mode 1))

;;; Keycast mode
(use-package keycast
  :config
  (with-eval-after-load 'jp-modeline
    (setq keycast-mode-line-format "%2s%k%c%R")
    (setq keycast-mode-line-insert-after 'jp-modeline-vc-branch)
    (setq keycast-mode-line-window-predicate 'mode-line-window-selected-p)
    (setq keycast-mode-line-remove-tail-elements nil))
  (with-eval-after-load 'keycast
    (dolist (input '(self-insert-command org-self-insert-command))
      (add-to-list 'keycast-substitute-alist `(,input "." "Typing…")))
    (dolist (event '("<mouse-event>" "<mouse-movement>" "<mouse-2>" "<drag-mouse-1>" "<wheel-up>" "<wheel-down>" "<double-wheel-up>" "<double-wheel-down>" "<triple-wheel-up>" "<triple-wheel-down>" "<wheel-left>" "<wheel-right>" handle-select-window mouse-set-point mouse-drag-region))
      (add-to-list 'keycast-substitute-alist `(,event nil nil)))))

(provide 'emacs-jp-modeline)

;;; emacs-jp-modeline.el ends here
