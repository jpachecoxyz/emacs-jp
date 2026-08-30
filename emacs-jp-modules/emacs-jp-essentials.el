;;; emacs-jp-essentials.el --- Essential configurations, modes and utilities -*- lexical-binding: t; -*-

;;; Commentary:

;; Core settings, general custom functions and a series of essential
;; modes: auto-package-update, substitute, goto-chg, tmr,
;; password-store, no-littering, vterm, and so on.

;;; Code:

;;; Emacs auto-update packages
(use-package auto-package-update
  :config
  (setq auto-package-update-interval 7
        auto-package-update-prompt-before-update t
        auto-package-update-hide-results t
        auto-package-update-at-time "09:00")
  (auto-package-update-maybe))

;;; Essential configurations
;;;; General settings and common custom functions (jp-simple.el)
(setq backward-delete-char-untabify-method 'hungry)
(setq blink-matching-paren nil)
(setq custom-unlispify-tag-names nil)
(setq delete-pair-blink-delay 0.1) ; Emacs 28 -- see `jp-simple-delete-pair-dwim'
(setq delete-pair-push-mark t) ; Emacs 31
(setq echo-keystrokes-help nil) ; Emacs 30
(setq epa-keys-select-method 'minibuffer) ; Emacs 30
(setq eval-expression-print-length nil)
(setq find-library-include-other-files nil) ; Emacs 29
(setq help-window-select t)
(setq help-window-keep-selected t) ; Emacs 29
(setq kill-do-not-save-duplicates t)
(setq mode-require-final-newline 'visit-save)
(setq next-error-recenter '(4)) ; center of the window
(setq remote-file-name-inhibit-auto-save t)                 ; Emacs 30
(setq remote-file-name-inhibit-delete-by-moving-to-trash t) ; Emacs 30
(setq save-interprogram-paste-before-kill t)
(setq scroll-error-top-bottom t)
(setq tramp-connection-timeout (* 60 10)) ; seconds
(setq trusted-content '("~/Documents/Emacs/" "~/.dotfiles")) ; Emacs 30
(setq truncate-partial-width-windows nil)
(setq pixel-scroll-precision-mode t)

;; Keys unbound here are either to avoid accidents or to bind them.
(define-key global-map (kbd "<f1>") #'vterm-toggle)
(define-key global-map (kbd "<f2>") #'toggle-input-method)
(define-key global-map (kbd "S-<f2>") #'keycast-mode-line-mode)
(define-key global-map (kbd "C-<f9>") #'jp-toggle-presentation-mode)
(define-key global-map (kbd "<f8>") #'jp/toggle-transparency)
(define-key global-map (kbd "<f12>") #'jp-emacs-toggle-calendar)
(define-key global-map (kbd "<insert>") nil)
(define-key global-map (kbd "<menu>") nil)
(define-key global-map (kbd "C-x C-d") nil) ; never use it
(define-key global-map (kbd "C-x C-v") nil) ; never use it
(define-key global-map (kbd "C-z") nil) ; a window manager is available
(define-key global-map (kbd "C-x C-z") nil) ; same idea as above
(define-key global-map (kbd "C-x C-c") nil) ; avoid accidentally exiting Emacs
(define-key global-map (kbd "C-x C-c C-c") #'save-buffers-kill-emacs) ; more cumbersome, less error-prone
(define-key global-map (kbd "C-h h") nil) ; never show that "hello" file
(define-key global-map (kbd "M-`") nil)
(define-key global-map (kbd "M-o") #'delete-blank-lines) ; alias for C-x C-o
(define-key global-map (kbd "M-SPC") #'cycle-spacing)
(define-key global-map (kbd "M-z") #'zap-up-to-char) ; NOT `zap-to-char'
(define-key global-map (kbd "M-c") #'capitalize-dwim)
(define-key global-map (kbd "M-l") #'downcase-dwim) ; "lower" case
(define-key global-map (kbd "M-u") #'upcase-dwim)
(define-key global-map (kbd "M-=") #'count-words)
(define-key global-map (kbd "C-x O") #'next-multiframe-window)
(define-key global-map (kbd "C-h K") #'describe-keymap) ; overrides `Info-goto-emacs-key-command-node'
(define-key global-map (kbd "C-h u") #'apropos-user-option)
(define-key global-map (kbd "C-h F") #'apropos-function) ; lower case is `describe-function'
(define-key global-map (kbd "C-h V") #'apropos-variable) ; lower case is `describe-variable'
(define-key global-map (kbd "C-h L") #'apropos-library) ; lower case is `view-lossage'
(define-key global-map (kbd "C-h c") #'describe-char) ; overrides `describe-key-briefly'

(define-key prog-mode-map (kbd "C-M-d") #'up-list) ; confusing name for what looks like "down"
(define-key prog-mode-map (kbd "<C-M-backspace>") #'backward-kill-sexp)

;; Keymap for buffers (Emacs 28)
(define-key ctl-x-x-map (kbd "f") #'follow-mode)  ; override `font-lock-update'
(define-key ctl-x-x-map (kbd "r") #'rename-uniquely)
(define-key ctl-x-x-map (kbd "l") #'visual-line-mode)

(require 'jp-common)

(defvar jp/fundamental-mode-hook nil
  "Normal hook for `fundamental-mode' (which is missing by default).")

(defun jp/fundamental-mode-run-hook (&rest args)
  "Apply ARGS and then run `jp/fundamental-mode-hook'."
  (apply args)
  (run-hooks 'jp/fundamental-mode-hook))

(advice-add #'fundamental-mode :around #'jp/fundamental-mode-run-hook)

(add-hook 'text-mode-hook #'jp-common-truncate-lines-silently)
(add-hook 'prog-mode-hook #'jp-common-truncate-lines-silently)
(add-hook 'dired-mode-hook #'jp-common-truncate-lines-silently)
(add-hook 'jp/fundamental-mode-hook #'jp-common-truncate-lines-silently)
(add-hook 'hexl-mode-hook #'jp-common-truncate-lines-silently)
(add-hook 'comint-mode-hook #'jp-common-truncate-lines-silently)

;; NEVER tell which key can call a command invoked with M-x.
(advice-add #'execute-extended-command--describe-binding-msg :override #'jp-common-ignore)

(require 'jp-simple)

(setq jp-simple-date-specifier "%F")
(setq jp-simple-time-specifier "%R %z")

(advice-add #'save-buffers-kill-emacs :before #'jp-simple-display-unsaved-buffers-on-exit)

;; All `jp-simple-override-mode' does is activate a key map.
;; Below add keys to that map.  Because the mode is enabled
;; globally, those keys take precedence over the ones specified by
;; any given major mode.
(jp-simple-override-mode 1)

(defun jp/simple-hex-highlight ()
  (when-let* ((file buffer-file-name)
              ((derived-mode-p 'emacs-lisp-mode))
              ((string-match-p "-theme" file)))
    (jp-simple-hex-color-mode 1)))

(add-hook 'emacs-lisp-mode-hook #'jp/simple-hex-highlight)

(define-key ctl-x-x-map (kbd "c") #'jp-simple-hex-color-mode) ; C-x x c

(define-key jp-simple-override-mode-map (kbd "C-a") #'jp-simple-duplicate-line-or-region) ; "again" mnemonic, overrides `move-beginning-of-line'
(define-key jp-simple-override-mode-map (kbd "C-d") #'jp-simple-delete-line) ; overrides `delete-char'
(define-key jp-simple-override-mode-map (kbd "C-v") #'jp-simple-multi-line-below) ; overrides `scroll-up-command'
(define-key jp-simple-override-mode-map (kbd "<next>") #'jp-simple-multi-line-below) ; overrides `scroll-up-command'
(define-key jp-simple-override-mode-map (kbd "M-v") #'jp-simple-multi-line-above) ; overrides `scroll-down-command'
(define-key jp-simple-override-mode-map (kbd "<prior>") #'jp-simple-multi-line-above) ; overrides `scroll-down-command'
(define-key jp-simple-override-mode-map (kbd "C-M-i") #'jp-simple-indent-dwim) ; overrides `completion-at-point'
(define-key jp-simple-override-mode-map (kbd "C-M-\\") #'jp-simple-indent-dwim) ; overrides `indent-region'
(define-key jp-simple-override-mode-map (kbd "C-M-c") #'completion-at-point) ; overrides `exit-recursive-edit'

(define-key global-map (kbd "C-h h") #'jp-simple-describe-at-point)
(define-key global-map (kbd "<escape>") #'jp-simple-keyboard-quit-dwim)
(define-key global-map (kbd "C-g") #'jp-simple-keyboard-quit-dwim)
(define-key global-map (kbd "C-M-SPC") #'jp-simple-mark-sexp)
(define-key global-map (kbd "C-x 0") #'jp-simple-delete-window-dwim) ; overrides `delete-window'
;; Commands for lines
(define-key global-map (kbd "C-S-d") #'jp-simple-delete-line-backward)
(define-key global-map (kbd "C-S-k") #'jp-simple-kill-line-backward)
(define-key global-map (kbd "M-k") #'jp-simple-copy-line-forward)
(define-key global-map (kbd "M-K") #'jp-simple-copy-line-backward)
(define-key global-map (kbd "M-j") #'delete-indentation)
(define-key global-map (kbd "C-w") #'jp-simple-kill-region)
(define-key global-map (kbd "M-w") #'jp-simple-kill-ring-save)
(define-key global-map (kbd "C-S-w") #'jp-simple-copy-line)
(define-key global-map (kbd "C-S-y") #'jp-simple-yank-replace-line-or-region)
(define-key global-map (kbd "<C-return>") #'jp-simple-new-line-below)
(define-key global-map (kbd "<C-S-return>") #'jp-simple-new-line-above)
(define-key global-map (kbd "C-x x a") #'jp-simple-auto-fill-visual-line-mode) ; auto-fill/visual-line toggle
;; Commands for text insertion or manipulation
(define-key global-map (kbd "C-=") #'jp-simple-insert-date)
(define-key global-map (kbd "C-<") #'jp-simple-escape-url-dwim)
(define-key global-map (kbd "C->") #'jp-simple-escape-url-dwim)
(define-key global-map (kbd "M-Z") #'jp-simple-zap-to-char-backward)
;; Commands for object transposition
(define-key global-map (kbd "C-S-p") #'jp-simple-move-above-dwim)
(define-key global-map (kbd "C-S-n") #'jp-simple-move-below-dwim)
(define-key global-map (kbd "C-t") #'jp-simple-transpose-chars)
(define-key global-map (kbd "C-x C-t") #'jp-simple-transpose-lines)
(define-key global-map (kbd "C-S-t") #'jp-simple-transpose-paragraphs)
(define-key global-map (kbd "C-x M-t") #'jp-simple-transpose-sentences)
(define-key global-map (kbd "C-M-t") #'jp-simple-transpose-sexps)
(define-key global-map (kbd "M-t") #'jp-simple-transpose-words)
;; Commands for paragraphs
(define-key global-map (kbd "M-Q") #'jp-simple-unfill-region-or-paragraph)
;; Commands for windows and pages
(define-key global-map (kbd "C-x o") #'jp-simple-other-window)
(define-key global-map (kbd "C-x n k") #'jp-simple-delete-page-delimiters)
(define-key global-map (kbd "M-r") #'window-layout-transpose) ; Emacs 31 override `move-to-window-line-top-bottom'
(define-key global-map (kbd "M-S-r") #'rotate-windows-back) ; Emacs 31
;; Commands for buffers
(define-key global-map (kbd "C-<f2>") #'jp-simple-rename-file-and-buffer)
(define-key global-map (kbd "M-<f2>") #'jp-simple-copy-current-path)
(define-key global-map (kbd "C-x k") #'jp-simple-kill-buffer-dwim)
(define-key global-map (kbd "C-x K") #'kill-buffer) ; left here to contrast with the above
(define-key global-map (kbd "M-s b") #'jp-simple-buffers-major-mode)
(define-key global-map (kbd "M-s v") #'jp-simple-buffers-vc-root)

;;;; Scratch buffers per major mode (jp-scratch.el)
(setq jp-scratch-default-mode 'text-mode)
(autoload #'jp-scratch-buffer "jp-scratch")
(define-key global-map (kbd "C-c s") #'jp-scratch-buffer)

;;;; Insert character pairs (jp-pair.el)
(autoload #'jp-pair-insert "jp-pair")
(autoload #'jp-pair-insert-directly "jp-pair")
(autoload #'jp-pair-delete "jp-pair")
(define-key global-map (kbd "C-'") #'jp-pair-insert)
(define-key global-map (kbd "M-'") #'jp-pair-insert-directly)
(define-key global-map (kbd "M-\\") #'jp-pair-delete)

;;;; Comments (jp-comment.el)
(setq comment-empty-lines t)
(setq comment-fill-column nil)
(setq comment-multi-line t)
(setq comment-style 'multi-line)
(setq-default comment-column 0)

(setq jp-comment-comment-keywords '("TODO" "NOTE" "FIXME"))
(setq jp-comment-timestamp-format-concise "%F")
(setq jp-comment-timestamp-format-verbose "%F %T %z")

(autoload #'jp-comment "jp-comment")
(autoload #'jp-comment-timestamp-keyword "jp-comment")

(define-key global-map (kbd "C-;") #'jp-comment)
(define-key global-map (kbd "M-;") #'jp-comment) ; overrides `comment-dwim'
(define-key global-map (kbd "C-x C-;") #'jp-comment-timestamp-keyword)

;;;; Prefix keymap (jp-prefix.el)
(require 'jp-prefix)
(define-key global-map (kbd "<insert>") #'jp-prefix)
(define-key global-map (kbd "C-z") #'jp-prefix)

(define-key global-map (kbd "C-x C-r") #'recentf-open) ; override `find-file-read-only'

(with-eval-after-load 'recentf
  (setq recentf-max-saved-items 100)
  (setq recentf-max-menu-items 25)
  (setq recentf-save-file-modes nil)
  (setq recentf-keep nil)
  (setq recentf-auto-cleanup nil)
  (setq recentf-initialize-file-name-history nil)
  (setq recentf-filename-handlers nil)
  (setq recentf-show-file-shortcuts-flag nil)
  (recentf-mode 1))

;;;; Mouse and mouse wheel behaviour
(mouse-wheel-mode 1)
;; Some of these variables are defined in places other than mouse.el.
(setq mouse-autoselect-window t) ; complements the auto-selection of the tiling window manager
(setq focus-follows-mouse t)

;; In Emacs 27+, use Control + mouse wheel to scale text.
(setq mouse-wheel-scroll-amount
      '(1
        ((shift) . 5)
        ((meta) . 0.5)
        ((control) . text-scale))
      mouse-drag-copy-region nil
      make-pointer-invisible t
      mouse-wheel-progressive-speed t
      mouse-wheel-follow-mouse t)

;; Scrolling behaviour
(setq scroll-preserve-screen-position t
      scroll-conservatively 8 ; affects `scroll-step'
      scroll-margin 5
      next-screen-context-lines 0
      pixel-scroll-precision-use-momentum nil)

;;;; Repeatable key chords (repeat-mode)
(repeat-mode 1)

(setq repeat-on-final-keystroke t
      repeat-exit-timeout 5
      repeat-exit-key "<escape>"
      repeat-keep-prefix nil
      repeat-check-key t
      repeat-echo-function 'ignore
      ;; Technically, this is not in repeat.el, though it is the same idea.
      set-mark-command-repeat-pop t)

;;;; Built-in bookmarking framework (bookmark.el)
(add-hook 'bookmark-bmenu-mode-hook #'hl-line-mode)
(setq bookmark-use-annotations nil)
(setq bookmark-automatically-show-annotations nil)
(setq bookmark-fringe-mark nil) ; Emacs 29 to hide bookmark fringe icon
;; Write changes to the bookmark file as soon as 1 modification is made.
(setq bookmark-save-flag 1)

;;;; Registers (register.el) and extensions (jp-register.el)
(require 'jp-register)

(unless register-alist
  (setq register-alist (jp-register-load)))

(define-key global-map (kbd "C-, a") #'jp-register-add-dwim)
(define-key global-map (kbd "C-, u") #'jp-register-use-dwim)
(define-key global-map (kbd "C-, j") #'bookmark-jump) ; alternative to C-x r b

(with-eval-after-load 'pulsar
  (add-hook 'jp-simple-file-to-register-jump-hook #'pulsar-recenter-center)
  (add-hook 'jp-simple-file-to-register-jump-hook #'pulsar-reveal-entry))

(setq register-preview-delay 0.5
      register-preview-function #'register-preview-default)

(jp-register-persist-mode 1)

;;;; Auto revert mode
(global-auto-revert-mode 1)
(setq auto-revert-verbose t)

;;;; Delete selection
(delete-selection-mode 1)

;;;; Tooltips (tooltip-mode)
(tooltip-mode 1)
(setq tooltip-delay 0.5
      tooltip-short-delay 0.5
      x-gtk-use-system-tooltips t
      tooltip-frame-parameters
      '((name . "tooltip")
        (internal-border-width . 10)
        (border-width . 0)
        (no-special-glyphs . t)))

;;;; Display current time
(setq display-time-format " %a %e %b, %H:%M ")
(setq display-time-interval 60)
(setq display-time-default-load-average nil)
;; For all those, a custom solution also shows the number of new items,
;; but it depends on notmuch: the `notmuch-indicator' package.
(setq display-time-mail-directory nil)
(setq display-time-mail-function nil)
(setq display-time-use-mail-icon nil)
(setq display-time-mail-string nil)
(setq display-time-mail-face nil)

;; No need for the load average and the mail indicator.
(setq display-time-string-forms
      '((propertize
         (format-time-string display-time-format now)
         'face 'display-time-date-and-time
         'help-echo (format-time-string "%a %b %e, %Y" now))
        " "))

(display-time-mode 1)

;;;; World clock (M-x world-clock)
(setq display-time-world-list t)
(setq zoneinfo-style-world-list
      '(("America/Los_Angeles" "Los Angeles")
        ("America/Vancouver" "Vancouver")
        ("America/Chicago" "Chicago")
        ("America/Toronto" "Toronto")
        ("America/New_York" "New York")
        ("UTC" "UTC")
        ("Europe/Lisbon" "Lisbon")
        ("Europe/Brussels" "Brussels")
        ("Europe/Athens" "Athens")
        ("Asia/Riyadh" "Riyadh")
        ("Asia/Tbilisi" "Tbilisi")
        ("Asia/Singapore" "Singapore")
        ("Asia/Shanghai" "Shanghai")
        ("Asia/Seoul" "Seoul")
        ("Asia/Tokyo" "Tokyo")
        ("Australia/Brisbane" "Brisbane")
        ("Australia/Sydney" "Sydney")
        ("Pacific/Auckland" "Auckland")))

;; All of the following variables are for Emacs 28.
(setq world-clock-list t)
(setq world-clock-time-format "%z %R\t%a %d %b (%Z)")
(setq world-clock-buffer-name "*world-clock*") ; placement handled by `display-buffer-alist'
(setq world-clock-timer-enable t)
(setq world-clock-timer-second 60)

;;;; `man' (manpages)
(setq Man-notify-method 'pushy) ; does not obey `display-buffer-alist'

;;;; `proced' (process monitor, similar to `top')
(setq proced-auto-update-flag 'visible) ; Emacs 30 supports the `visible' value
(setq proced-enable-color-flag t) ; Emacs 29
(setq proced-auto-update-interval 5)
(setq proced-descend t)
(setq proced-filter 'user)

;;;; Emacs server (emacsclient)
(setq server-client-instructions nil)
(require 'server)
(unless (or (server-running-p) (daemonp))
  (server-start))

;;; Substitute
(use-package substitute
  :config
  (require 'substitute)

  ;; Produce a message after the substitution that reports on what
  ;; happened.
  (add-hook 'substitute-post-replace-hook #'substitute-report-operation)

  ;; Highlight all occurrences of the current target.
  (setopt substitute-highlight t)

  ;; Treat letter casing literally, or use a C-u prefix argument.
  (setq substitute-fixed-letter-case nil)

  ;; C-c s is occupied by `jp-scratch-buffer'.
  (define-key global-map (kbd "C-c r") #'substitute-prefix-map))

;;; goto-chg
(use-package goto-chg
  :config
  (define-key global-map (kbd "C-(") #'goto-last-change)
  (define-key global-map (kbd "C-)") #'goto-last-change-reverse))

;;; TMR May Ring (tmr sets timers)
(use-package tmr
  :config
  (define-key global-map (kbd "C-c t") #'tmr-prefix-map)
  (setq tmr-sound-file "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
        tmr-notification-urgency 'normal
        tmr-description-list 'tmr-description-history))

;;; Pass interface (password-store)
(use-package password-store
  :config
  ;; Mnemonic is the root of the "code" word (κώδικας).
  (define-key global-map (kbd "C-c k") #'password-store-copy)
  (setq password-store-time-before-clipboard-restore 30))

(use-package pass)

;;; Backup files
(use-package no-littering
  :config
  ;; no-littering does not set this by default, so auto save files are
  ;; placed in the same path it uses for sessions.
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t))))

;;; Generic interface for shells or REPLs (comint)
(progn
  ;; Support for OS-specific escape sequences such as `ls --hyperlink'.
  (add-hook 'comint-output-filter-functions #'comint-osc-process-output)

  (setq ansi-color-for-comint-mode t) ; also see `ansi-color-for-compilation-mode'
  (setq comint-prompt-read-only t)
  (setq comint-buffer-maximum-size 9999)
  (setq comint-completion-autolist t)
  (setq comint-input-ignoredups t)
  (setq-default comint-scroll-to-bottom-on-input t)
  (setq-default comint-scroll-to-bottom-on-output nil)
  (setq-default comint-input-autoexpand 'input))

;;; Compilation interface (M-x compile)
(add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)
(setq ansi-color-for-compilation-mode t) ; also see `ansi-color-for-comint-mode'

;;; Standard Unix Shell (M-x shell)
(use-package vterm
  :config
  ;; Start in insert state if using evil
  (add-hook 'vterm-mode-hook (lambda () (evil-insert-state)))

  ;; Allow F1 toggle inside vterm
  (define-key vterm-mode-map (kbd "<f1>") #'vterm-toggle)

  ;; Kill buffer when closing terminal
  (setq vterm-kill-buffer-on-exit t))

(use-package vterm-toggle
  :config
  (setq vterm-toggle-use-dedicated-buffer t)
  (setq vterm-toggle-fullscreen-p nil)
  (setq vterm-toggle-reset-window-configuration-after-exit nil)
  (setq vterm-toggle-display-action nil))

;;; Transparency
(when jp-emacs-enable-transparency
  (defun jp/clear-terminal-background-color (&optional frame)
    "Unset background color in terminal mode, including line numbers."
    (interactive)
    (or frame (setq frame (selected-frame)))
    (unless (display-graphic-p frame)
      (send-string-to-terminal
       (format "\033]11;[90]%s\033\\"
               (face-attribute 'default :background)))
      (set-face-background 'default "unspecified-bg" frame)
      (set-face-background 'line-number "unspecified-bg" frame)
      (set-face-background 'line-number-current-line "unspecified-bg" frame)))

  (defun jp/set-transparency (&optional frame)
    "Apply transparency to FRAME or all frames."
    (interactive)

    ;; Terminal transparency fix
    (unless (display-graphic-p frame)
      (add-hook 'window-setup-hook #'jp/clear-terminal-background-color)
      (add-hook 'ef-themes-post-load-hook #'jp/clear-terminal-background-color))

    (if frame
        (progn
          (when (eq system-type 'darwin)
            (set-frame-parameter frame 'alpha '(90 90)))
          (set-frame-parameter frame 'alpha-background 85))

      (dolist (frm (frame-list))
        (when (eq system-type 'darwin)
          (set-frame-parameter frm 'alpha '(90 90)))
        (set-frame-parameter frm 'alpha-background 85))))

  (defun jp/unset-transparency ()
    "Disable frame transparency."
    (interactive)
    (when (eq system-type 'darwin)
      (set-frame-parameter (selected-frame) 'alpha '(100 100)))
    (dolist (frame (frame-list))
      (set-frame-parameter frame 'alpha-background 100)))

  (defun jp/toggle-transparency ()
    "Toggle frame transparency."
    (interactive)
    (setq jp-emacs-enable-transparency (not jp-emacs-enable-transparency))
    (if jp-emacs-enable-transparency
        (progn
          (jp/set-transparency)
          (message "Transparency enabled"))
      (jp/unset-transparency)
      (message "Transparency disabled")))

  ;; Hooks
  (add-hook 'after-init-hook #'jp/set-transparency)
  (add-hook 'after-make-frame-functions #'jp/set-transparency))

(defun jp-emacs-toggle-calendar ()
  "If the calendar is visible close its window, otherwise open it."
  (interactive)
  (let ((calendar-window (get-buffer-window "*Calendar*")))
    (if calendar-window
        (delete-window calendar-window)
      (calendar))))

(provide 'emacs-jp-essentials)

;;; emacs-jp-essentials.el ends here
