;;; emacs-jp-vertico.el --- Vertical completion layout (vertico) -*- lexical-binding: t; -*-

;;; Commentary:

;; Vertico provides a vertical completion UI.  The minor `vertico-*'
;; groups rely on the rfn-eshadow file-name shadowing machinery.

;;; Code:

(use-package vertico
  :config
  (setq vertico-scroll-margin 0)
  (setq vertico-count 5)
  (setq vertico-resize t)
  (setq vertico-cycle t)

  (with-eval-after-load 'rfn-eshadow
    ;; When you are in a sub-directory and use, say, `find-file' to go
    ;; to your home '~/' or root '/' directory, Vertico will clear the
    ;; old path to keep only your current input.
    (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy))

  (setq vertico-group-format
        (concat
         (propertize (make-string 20 ? ) 'face 'completions-group-separator)
         (propertize " %s " 'face 'completions-group-title)
         (propertize " " 'face 'completions-group-separator 'display '(space :align-to right))))

  (vertico-mode 1))

(provide 'emacs-jp-vertico)

;;; emacs-jp-vertico.el ends here
