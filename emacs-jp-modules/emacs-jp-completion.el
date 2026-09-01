;;; emacs-jp-completion.el --- Completion setup (minibuffer, corfu, consult, etc.) -*- lexical-binding: t; -*-

;;; Commentary:

;; Completion styles, per-category overrides, orderless, corfu,
;; consult, embark, marginalia and the minibuffer UI.  Optionally loads
;; the vertico (or mct) module.

;;; Code:

;;; General minibuffer settings
;;;; Completion styles
(setq completion-styles '(basic substring initials partial-completion flex)) ; also see `completion-category-overrides'
(setq completion-flex-nospace t)
(setq completion-pcm-leading-wildcard nil) ; Emacs 31
(with-eval-after-load 'orderless
  (setq completion-styles (append completion-styles '(orderless))))

;;;; Completion category overrides
;; Reset all the per-category defaults so that (i) we use the
;; standard `completion-styles' and (ii) can specify our own styles
;; in the `completion-category-overrides' without having to
;; explicitly override everything.
(require 'jp-minibuffer)
(setq completion-category-defaults nil)

(jp-minibuffer-missing-categories-mode 1)

;; The `eager-display' and `eager-update' are part of Emacs 31.
(let* ((eager-update-properties '((eager-display . nil)
                                  (eager-update . t)))
       (eager-update-properties-no-sort (append eager-update-properties (list (cons 'display-sort-function #'identity)))))
  (setq completion-category-overrides
        `((file . ((styles . (partial-completion))
                   (eager-display . nil)
                   (eager-update . t)
                   (group-function . ,#'jp-minibuffer-file-group)
                   (affixation-function . ,#'jp-minibuffer-file-affixate)
                   (display-sort-function . ,#'jp-minibuffer-file-sort)))
          (bookmark . (,@eager-update-properties
                       (affixation-function . ,#'jp-minibuffer-bookmark-affixate)))
          (project-file . (,@eager-update-properties
                           (group-function . ,#'jp-minibuffer-file-group)
                           (affixation-function . ,#'jp-minibuffer-file-affixate)))
          (jp-minibuffer-library . (,@eager-update-properties
                                    (annotation-function . ,#'jp-minibuffer-library-annotate)
                                    (display-sort-function . ,#'jp-minibuffer-library-sort)))
          (symbol-help . (,@eager-update-properties
                          (group-function . ,#'jp-minibuffer-symbol-group)
                          (display-sort-function . ,#'jp-minibuffer-symbol-sort)))
          (buffer . (,@eager-update-properties
                     (group-function . ,#'jp-minibuffer-buffer-group)
                     (affixation-function . ,#'jp-minibuffer-buffer-affixate)))
          (command . ((affixation-function . nil)
                      (annotation-function . ,#'jp-minibuffer-command-annotate)))
          (denote-file . ,eager-update-properties)
          (jp-minibuffer-emoji . ,eager-update-properties)
          (theme . ,eager-update-properties)
          (unicode-name . ,eager-update-properties)
          (imenu . ,eager-update-properties-no-sort)
          (consult-location . ,eager-update-properties-no-sort)
          (jp-minibuffer-kill-ring . ((eager-display . t)
                                      (eager-update . t)
                                      (display-sort-function . identity))))))


;;; Completion preview
(use-package completion-preview
  :ensure nil
  :demand t
  :bind
  (:map completion-preview-active-mode-map
        ("M-i" . completion-preview-insert-word)
        ("M-n" . completion-preview-next-candidate)
        ("M-p" . completion-preview-prev-candidate)
        ("M-<return>" . completion-preview-insert)
        ("<tab>" . completion-preview-complete))
  :config
  (setq completion-preview-minimum-symbol-length 2)
  (global-completion-preview-mode))

;;; Orderless completion style (and jp-orderless.el)
(when jp-emacs-completion-extras
  (use-package orderless
    :config
    ;; Remember to check the `completion-styles' and the
    ;; `completion-category-overrides'.
    (setq orderless-matching-styles '(orderless-prefixes orderless-regexp))
    (setq orderless-smart-case nil)

    ;; SPC should never complete: use it for `orderless' groups.
    ;; The `?' is a regexp construct.
    (define-key minibuffer-local-completion-map (kbd "SPC") nil)
    (define-key minibuffer-local-completion-map (kbd "?") nil)))

(setq completion-ignore-case t)
(setq read-buffer-completion-ignore-case t)
(setq-default case-fold-search t)   ; For general regexp
(setq read-file-name-completion-ignore-case t)
(setq minibuffer-history-case-insensitive-variables t)

(setq read-minibuffer-restore-windows nil)
(setq enable-recursive-minibuffers t) ; Emacs 28
(minibuffer-depth-indicate-mode 1)

(setq minibuffer-default-prompt-format " [%s]") ; Emacs 29
(minibuffer-electric-default-mode 1)

(setq resize-mini-windows t)
(setq read-answer-short t) ; also check `use-short-answers' for Emacs 28
(setq echo-keystrokes 0.25)
(setq kill-ring-max 60) ; Keep it small

(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)
;; Do not allow the cursor to move inside the minibuffer prompt.
(setq minibuffer-prompt-properties
      '(read-only t cursor-intangible t face minibuffer-prompt))

(setq crm-prompt (format "%s %%p" (propertize "[%d]" 'face 'shadow))) ; Emacs 31

(file-name-shadow-mode 1)

(add-hook 'completion-list-mode-hook #'jp-common-truncate-lines-silently)
(add-hook 'minibuffer-setup-hook #'jp-common-truncate-lines-silently)

(setq completions-group-format
      (concat
       (propertize (make-string 20 ? ) 'face 'completions-group-separator)
       (propertize " %s " 'face 'completions-group-title)
       (propertize " " 'face 'completions-group-separator 'display '(space :align-to right))))

(unless jp-emacs-completion-ui
  (jp-minibuffer-completions-mode 1)

  (define-key completion-list-mode-map (kbd "h") #'jp-minibuffer-completions-describe-at-point) ; "Help" mnemonic
  (define-key completion-list-mode-map (kbd "c") #'jp-minibuffer-choose-completion-no-exit) ; "Choose" mnemonic
  (define-key completion-list-mode-map (kbd "TAB") #'jp-minibuffer-choose-completion-dwim)
  (define-key completion-list-mode-map (kbd "RET") #'jp-minibuffer-choose-completion-exit))

;;;; `savehist' (minibuffer and related histories)
(setq savehist-file (locate-user-emacs-file "savehist"))
(setq history-length 100)
(setq history-delete-duplicates t)
(setq savehist-save-minibuffer-history t)
(with-eval-after-load 'savehist
  (add-to-list 'savehist-additional-variables 'kill-ring))
(savehist-mode 1)

;;;; `dabbrev' (dynamic word completion (dynamic abbreviations))
(setq dabbrev-abbrev-char-regexp "\\sw\\|\\s_")
(setq dabbrev-abbrev-skip-leading-regexp "[$*/=~']")
(setq dabbrev-backward-only nil)
(setq dabbrev-case-distinction 'case-replace)
(setq dabbrev-case-fold-search nil)
(setq dabbrev-case-replace 'case-replace)
(setq dabbrev-check-other-buffers t)
(setq dabbrev-eliminate-newlines t)
(setq dabbrev-upcase-means-case-search t)
(setq dabbrev-ignored-buffer-modes '(archive-mode image-mode docview-mode pdf-view-mode))

;;;; `abbrev' (Abbreviations, else Abbrevs)
;; message-mode derives from text-mode, so we don't need a separate
;; hook for it.
(add-hook 'text-mode-hook #'abbrev-mode)
(add-hook 'prog-mode-hook #'abbrev-mode)
(add-hook 'git-commit-mode-hook #'abbrev-mode)

(setq only-global-abbrevs nil)

(define-abbrev global-abbrev-table "xyz" "https://jpachecoxyz.github.io")
(define-abbrev global-abbrev-table "jpm" "jpacheco@disroot.org")
(define-abbrev global-abbrev-table "megit" "https://github.com/jpachecoxyz")
(define-abbrev global-abbrev-table "mehub" "https://github.com/jpachecoxyz")
(define-abbrev global-abbrev-table "meclone" "git@github.com/jpachecoxyz/")
(define-abbrev global-abbrev-table ";web" "https://jpachecoxyz.github.io")
(define-abbrev global-abbrev-table ";web" "https://jpachecoxyz.github.io")
(define-abbrev global-abbrev-table ";hub" "https://github.com/jpachecoxyz")
(define-abbrev global-abbrev-table ";clone" "git@github.com/jpachecoxyz/")

(define-abbrev text-mode-abbrev-table "asciidoc" "AsciiDoc")
(define-abbrev text-mode-abbrev-table "auctex" "AUCTeX")
(define-abbrev text-mode-abbrev-table "cafe" "café")
(define-abbrev text-mode-abbrev-table "cliche" "cliché")
(define-abbrev text-mode-abbrev-table "clojurescript" "ClojureScript")
(define-abbrev text-mode-abbrev-table "emacsconf" "EmacsConf")
(define-abbrev text-mode-abbrev-table "github" "GitHub")
(define-abbrev text-mode-abbrev-table "gitlab" "GitLab")
(define-abbrev text-mode-abbrev-table "javascript" "JavaScript")
(define-abbrev text-mode-abbrev-table "latex" "LaTeX")
(define-abbrev text-mode-abbrev-table "libreplanet" "LibrePlanet")
(define-abbrev text-mode-abbrev-table "linkedin" "LinkedIn")
(define-abbrev text-mode-abbrev-table "paypal" "PayPal")
(define-abbrev text-mode-abbrev-table "sourcehut" "SourceHut")
(define-abbrev text-mode-abbrev-table "texmacs" "TeXmacs")
(define-abbrev text-mode-abbrev-table "typescript" "TypeScript")
(define-abbrev text-mode-abbrev-table "visavis" "vis-à-vis")
(define-abbrev text-mode-abbrev-table "deja" "déjà")
(define-abbrev text-mode-abbrev-table "voila" "voilà")
(define-abbrev text-mode-abbrev-table "youtube" "YouTube")
(define-abbrev text-mode-abbrev-table ";up" "🙃")
(define-abbrev text-mode-abbrev-table ";uni" "🦄")
(define-abbrev text-mode-abbrev-table ";laugh" "🤣")
(define-abbrev text-mode-abbrev-table ";smile" "😀")
(define-abbrev text-mode-abbrev-table ";sun" "☀️")

;; Allow abbrevs with a prefix colon, semicolon, or underscore.
(abbrev-table-put global-abbrev-table :regexp "\\(?:^\\|[\t\s]+\\)\\(?1:[:;_].*\\|.*\\)")

(with-eval-after-load 'text-mode
  (abbrev-table-put text-mode-abbrev-table :regexp "\\(?:^\\|[\t\s]+\\)\\(?1:[:;_].*\\|.*\\)"))

(with-eval-after-load 'org
  (define-abbrev org-mode-abbrev-table ";dev" "{{{development-version}}}")
  (define-abbrev org-mode-abbrev-table ";key" "" #'jp-abbrev-org-macro-key)
  (define-abbrev org-mode-abbrev-table ";cmd" "" #'jp-abbrev-org-macro-key-command)
  (abbrev-table-put org-mode-abbrev-table :regexp "\\(?:^\\|[\t\s]+\\)\\(?1:[:;_].*\\|.*\\)"))

(with-eval-after-load 'message
  (define-abbrev message-mode-abbrev-table "bestregards" "Best regards,\nJavier Pacheco")
  (define-abbrev message-mode-abbrev-table "allthebest" "All the best,\nJavier Pacheco")
  (define-abbrev message-mode-abbrev-table "niceday" "Have a nice day,\nJavier Pacheco")
  (define-abbrev message-mode-abbrev-table "abest" "All the best,\nJP")
  (define-abbrev message-mode-abbrev-table "bregards" "Best regards,\nJP")
  (define-abbrev message-mode-abbrev-table "nday" "Have a nice day,\nJP"))

;; The `jp-emacs-abbrev' macro, which simplifies how we use
;; `define-abbrev', does not only expand a static text.  It can take
;; a pair of string and function to trigger the latter when the
;; former is inserted.  Think of it like the basis of a simplistic
;; templating system.
(require 'jp-abbrev)
(define-abbrev global-abbrev-table "metime" "" #'jp-abbrev-current-time)
(define-abbrev global-abbrev-table "medate" "" #'jp-abbrev-current-date)
(define-abbrev global-abbrev-table "mejitsi" "" #'jp-abbrev-jitsi-link)
(define-abbrev global-abbrev-table ";time" "" #'jp-abbrev-current-time)
(define-abbrev global-abbrev-table ";date" "" #'jp-abbrev-current-date)
(define-abbrev global-abbrev-table ";jitsi" "" #'jp-abbrev-jitsi-link)

(define-abbrev text-mode-abbrev-table ";update" "" #'jp-abbrev-update-html)

;; Because the *scratch* buffer is produced before we load this, we
;; have to explicitly activate the mode there.
(when-let* ((scratch (get-buffer "*scratch*")))
  (with-current-buffer scratch
    (abbrev-mode 1)))

;; By default, abbrev asks for confirmation on whether to use
;; `abbrev-file-name' to save abbrevations.  This is not needed.
(remove-hook 'save-some-buffers-functions #'abbrev--possibly-save)

;;; Corfu
(use-package corfu
  :config
  (setq corfu-auto t)
  (setq corfu-preview-current nil)
  (setq corfu-min-width 20)

  (setq corfu-popupinfo-delay '(1.25 . 0.1))
  (corfu-popupinfo-mode 1) ; shows documentation after `corfu-popupinfo-delay'

  (global-corfu-mode 1)

  ;; TAB completes when it does not need to perform an indentation change.
  (define-key corfu-map (kbd "<tab>") #'corfu-complete)

  ;; Sort by input history (no need to modify `corfu-sort-function').
  (with-eval-after-load 'savehist
    (corfu-history-mode 1)
    (add-to-list 'savehist-additional-variables 'corfu-history)))

;;; Enhanced minibuffer commands (consult.el)
(when jp-emacs-completion-extras
  (use-package consult
    :config
    (keymap-global-set "M-g M-g" #'consult-goto-line)
    (keymap-global-set "M-s M-b" #'consult-buffer)
    (keymap-global-set "M-s M-f" #'consult-find)
    (keymap-global-set "M-s M-g" #'consult-grep)
    (keymap-global-set "M-s M-h" #'consult-history)
    (keymap-global-set "M-s M-i" #'consult-imenu)
    (keymap-global-set "M-s M-l" #'consult-line)
    (keymap-global-set "M-s M-m" #'consult-mark)
    (keymap-global-set "M-s M-y" #'consult-yank-pop)
    (keymap-global-set "M-s M-s" #'consult-outline)

    (setq consult-line-numbers-widen t)
    (setq consult-async-min-input 3)
    (setq consult-async-input-debounce 0.5)
    (setq consult-async-input-throttle 0.8)
    (setq consult-narrow-key nil)
    (setq consult-find-args
          (concat "find . -not ( "
                  "-path */.git* -prune "
                  "-or -path */.cache* -prune )"))
    (setq consult-preview-key 'any)
    (setq consult-project-function nil) ; always work from the current directory (use `cd' to switch directory)

    ;; see the `pulsar' package
    (setq consult-after-jump-hook nil) ; reset to avoid conflicts with the custom function
    (with-eval-after-load 'pulsar
      (add-hook 'consult-after-jump-hook #'pulsar-recenter-top)
      (add-hook 'consult-after-jump-hook #'pulsar-reveal-entry))))

;;; Extended minibuffer actions and more (embark.el)
(when jp-emacs-completion-extras
  (use-package embark
    :config
    (add-hook 'embark-collect-mode-hook #'jp-common-truncate-lines-silently)

    (define-key minibuffer-local-map (kbd "C-c C-c") #'embark-collect)
    (define-key minibuffer-local-map (kbd "C-c C-e") #'embark-export)

    ;; Needed for correct exporting while using Embark with Consult commands.
    (use-package embark-consult
      :after consult
      :demand t
      :config
      (require 'embark-consult))))

;;; Detailed completion annotations (marginalia.el)
(when jp-emacs-completion-extras
  (use-package marginalia
    :config
    (setq marginalia-max-relative-age 0) ; absolute time
    (marginalia-mode 1)))

;;; The minibuffer user interface (mct, vertico, or none)
(when jp-emacs-completion-ui
  (require
   (pcase jp-emacs-completion-ui
     ('mct 'emacs-jp-mct)
     ('vertico 'emacs-jp-vertico))))

(provide 'emacs-jp-completion)

;;; emacs-jp-completion.el ends here
