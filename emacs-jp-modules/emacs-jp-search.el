;;; emacs-jp-search.el --- Isearch, occur, grep, and extras (jp-search) -*- lexical-binding: t; -*-

;;; Commentary:

;; Configuration for incremental search, occur, grep, xref and the
;; custom jp-search helpers.

;;; Code:

(setq search-whitespace-regexp ".*?")
(setq isearch-lax-whitespace t)
(setq isearch-regexp-lax-whitespace nil)

(setq search-highlight t)
(setq isearch-lazy-highlight t)
(setq lazy-highlight-initial-delay 0.5)
(setq lazy-highlight-no-delay-length 4)

(setq isearch-lazy-count t)
(setq lazy-count-prefix-format "(%s/%s) ")
(setq lazy-count-suffix-format nil)

(setq isearch-wrap-pause t) ; `no-ding' makes keyboard macros never quit
(setq isearch-repeat-on-direction-change t)

(setq list-matching-lines-jump-to-current-line nil) ; do not jump to current line in `*occur*' buffers
(add-hook 'occur-mode-hook #'jp-common-truncate-lines-silently)
(add-hook 'occur-mode-hook #'hl-line-mode)

(define-key global-map (kbd "C-.") #'isearch-forward-symbol-at-point)
(define-key minibuffer-local-isearch-map (kbd "M-/") #'isearch-complete-edit)
(define-key occur-mode-map (kbd "t") #'toggle-truncate-lines)
(keymap-set isearch-mode-map "C-g" #'isearch-cancel) ; instead of `isearch-abort'
(keymap-set isearch-mode-map "M-/" #'isearch-complete)

(require 'jp-search)

(keymap-global-set "M-s M-%" #'jp-search-replace-markup)
(keymap-global-set "M-s M-<" #'jp-search-isearch-beginning-of-buffer)
(keymap-global-set "M-s M->" #'jp-search-isearch-end-of-buffer)
(keymap-global-set "M-s g" #'jp-search-grep)
(keymap-global-set "M-s u" #'jp-search-occur-urls)
(keymap-global-set "M-s t" #'jp-search-occur-todo-keywords)
(keymap-global-set "M-s M-t" #'jp-search-grep-todo-keywords)
(keymap-global-set "M-s M-T" #'jp-search-git-grep-todo-keywords)
(keymap-global-set "M-s s" #'jp-search-outline)
(keymap-global-set "M-s M-o" #'jp-search-occur-outline)
(keymap-global-set "M-s M-u" #'jp-search-occur-browse-url)

(keymap-set isearch-mode-map "<up>" #'jp-search-isearch-repeat-backward)
(keymap-set isearch-mode-map "<down>" #'jp-search-isearch-repeat-forward)
(keymap-set isearch-mode-map "<backspace>" #'jp-search-isearch-abort-dwim)
(keymap-set isearch-mode-map "C-<return>" #'jp-search-isearch-other-end)

(setq jp-search-outline-regexp-alist
      '((emacs-lisp-mode . "^\\((\\|;;;+ \\)")
        (org-mode . "^\\(\\*+ +\\|#\\+[Tt][Ii][Tt][Ll][Ee]:\\)")
        (outline-mode . "^\\*+ +")
        (emacs-news-view-mode . "^\\*+ +")
        (conf-toml-mode . "^\\[")
        (markdown-mode . "^#+ +")))

(setq jp-search-todo-keywords
      (concat "TODO\\|FIXME\\|NOTE\\|REVIEW\\|XXX\\|KLUDGE"
              "\\|HACK\\|WARN\\|WARNING\\|DEPRECATED\\|BUG"))

(add-hook 'jp-search-outline-hook #'pulsar-recenter-center)
(add-hook 'jp-search-outline-hook #'pulsar-reveal-entry)

;;; grep and xref
(setq reb-re-syntax 'read)

(let ((ripgrep (or (executable-find "rg") (executable-find "ripgrep"))))
  ;; All those have been changed for Emacs 28
  (setq xref-show-definitions-function #'xref-show-definitions-completing-read) ; for M-.
  (setq xref-show-xrefs-function #'xref-show-definitions-buffer) ; for grep and the like
  (setq xref-file-name-display 'project-relative)
  (setq xref-search-program (if ripgrep 'ripgrep 'grep))

  (setq grep-save-buffers nil)
  (setq grep-use-headings nil) ; Emacs 30

  (setq grep-program (or ripgrep (executable-find "grep")))
  (setq grep-template
        (if ripgrep
            "/usr/bin/rg -nH --null -e <R> <F>"
          "/usr/bin/grep <X> <C> -nH --null -e <R> <F>")))

(add-hook 'grep-mode #'jp-common-truncate-lines-silently)

;;; wgrep (writable grep)
;; See the `grep-edit-mode' for the new built-in feature.
(when (< emacs-major-version 31)
  (use-package wgrep
    :config
    (with-eval-after-load 'grep
      (keymap-set grep-mode-map "e" #'wgrep-change-to-wgrep-mode)
      (keymap-set grep-mode-map "C-x C-q" #'wgrep-change-to-wgrep-mode)
      (keymap-set grep-mode-map "C-c C-c" #'wgrep-finish-edit)
      (setq wgrep-auto-save-buffer t)
      (setq wgrep-change-readonly-file t))))

(provide 'emacs-jp-search)

;;; emacs-jp-search.el ends here
