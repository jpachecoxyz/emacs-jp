;;; emacs-jp-icons.el --- Icons -*- lexical-binding: t; -*-

;;; Commentary:

;; File icons for Dired via all-the-icons-dired.

;;; Code:

(use-package all-the-icons-dired
  :config
  (with-eval-after-load 'dired
    (add-hook 'dired-mode-hook #'all-the-icons-dired-mode)))

(provide 'emacs-jp-icons)

;;; emacs-jp-icons.el ends here
