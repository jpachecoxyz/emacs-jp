;;; emacs-jp-spell.el --- Spell checking (hunspell + jinx) -*- lexical-binding: t; -*-

;;; Commentary:

;; Hunspell dictionary setup for English and Spanish, plus the Jinx
;; spell checker package.

;;; Code:

;;========================
;; Hunspell / Dictionaries
;;========================

(setq ispell-program-name "hunspell")

(setq ispell-hunspell-dict-paths-alist
      '(("en_US" "~/.dotfiles/.emacs.d/lang/en_US.aff")
        ("es_MX" "~/.dotfiles/.emacs.d/lang/es_MX.aff")))

(setq ispell-local-dictionary-alist
      '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil nil nil utf-8)
        ("es_MX" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil nil nil utf-8)))

(setq ispell-local-dictionary "en_US")

(defvar jp/ispell-current-dictionary "en_US")

(defun jp/toggle-ispell-dictionary ()
  "Toggle between English and Spanish hunspell dictionaries."
  (interactive)
  (if (string= jp/ispell-current-dictionary "en_US")
      (progn
        (setq jp/ispell-current-dictionary "es_MX")
        (message "Switched to Spanish dictionary"))
    (progn
      (setq jp/ispell-current-dictionary "en_US")
      (message "Switched to English dictionary")))
  (ispell-change-dictionary jp/ispell-current-dictionary))

;;========================
;; Jinx spell checker
;;========================

(use-package jinx
  :config
  (require 'jinx)

  (dolist (hook '(text-mode-hook conf-mode-hook))
    (add-hook hook #'jinx-mode))

  (global-set-key (kbd "M-;") #'jinx-correct))
;; (global-set-key (kbd "<f8>") #'jinx-languages))

(provide 'emacs-jp-spell)

;;; emacs-jp-spell.el ends here
