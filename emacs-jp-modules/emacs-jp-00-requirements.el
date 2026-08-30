;;; emacs-jp-00-requirements.el --- Package sources, pinning and vc installs -*- lexical-binding: t; -*-

;;; Commentary:

;; Central place for anything that has to do with *where* packages come
;; from.  The archives and priorities are set in init.el already; here
;; we deal with:
;;
;;   - pinning my own (Protesilaos) packages to the gnu-elpa-devel
;;     archive so they always carry the latest development snapshot;
;;   - installing the handful of packages that only exist as git
;;     repositories (typst-ts-mode, pixel-themes, buffer-to-pdf) via
;;     `use-package :vc'.

;;; Code:

;; ---------------------------------------------------------------------
;; My own packages, pinned to gnu-elpa-devel (development snapshots).
;; ---------------------------------------------------------------------

(defvar jp-emacs-my-packages
  '(agitate
    altcaps
    beframe
    buffer-to-pdf
    consult-denote
    cursory
    denote
    denote-journal
    denote-markdown
    denote-merge
    denote-org
    denote-silo
    denote-sequence
    dired-preview
    doric-themes
    ef-themes
    fontaine
    lin
    logos
    mct
    modus-themes
    notmuch-indicator
    pulsar
    show-font
    spacious-padding
    standard-themes
    substitute
    tmr)
  "List of symbols representing the packages I develop/maintain.")

(with-eval-after-load 'package
  (setq package-pinned-packages
        (mapcar (lambda (package)
                  (cons package "gnu-elpa-devel"))
                jp-emacs-my-packages)))

;; ---------------------------------------------------------------------
;; Packages that only exist as git repositories, installed with
;; `use-package :vc'.
;; ---------------------------------------------------------------------

;; Typst major mode, straight from Codeberg.
(use-package typst-ts-mode
  :vc (:url "https://codeberg.org/meow_king/typst-ts-mode" :branch "main" :lisp-dir ".")
  :defer t)

;; My secondary theme family, from GitHub.
(use-package pixel-themes
  :vc (:url "https://github.com/lucasobx/pixel-themes")
  :defer t)

;; PDF from a buffer (Protesilaos), from GitHub.
(use-package buffer-to-pdf
  :vc (:url "https://github.com/protesilaos/buffer-to-pdf")
  :defer t)

(provide 'emacs-jp-00-requirements)

;;; emacs-jp-00-requirements.el ends here
