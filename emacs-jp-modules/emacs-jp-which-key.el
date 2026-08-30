;;; emacs-jp-which-key.el --- Which-key configuration -*- lexical-binding: t; -*-

;;; Commentary:

;; which-key is built into Emacs 30 as a core library.  This module
;; just tunes a few options and enables the global mode.

;;; Code:

(use-package which-key
  :ensure nil                       ; built into Emacs 30
  :config
  (setq which-key-separator "  ")
  (setq which-key-prefix-prefix "... ")
  (setq which-key-max-display-columns 3)
  (setq which-key-idle-delay 1.5)
  (setq which-key-idle-secondary-delay 0.25)
  (setq which-key-add-column-padding 1)
  (setq which-key-max-description-length 40)
  (which-key-mode 1))

(provide 'emacs-jp-which-key)

;;; emacs-jp-which-key.el ends here
