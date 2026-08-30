;;; emacs-jp-lsp.el --- LSP-mode configuration -*- lexical-binding: t; -*-

;;; Commentary:

;; Language Server Protocol support via lsp-mode, plus lsp-ui.

;;; Code:

(use-package lsp-mode
  :config
  ;; start lsp automatically
  (add-hook 'prog-mode-hook #'lsp-deferred)

  ;; performance tweaks
  (setq lsp-idle-delay 0.2)
  (setq lsp-log-io nil)
  (setq lsp-completion-provider :capf)
  (setq lsp-headerline-breadcrumb-enable nil)
  (setq lsp-enable-symbol-highlighting t)
  (setq lsp-enable-on-type-formatting nil)

  ;; disable things that slow lsp
  (setq lsp-modeline-code-actions-enable nil)
  (setq lsp-modeline-diagnostics-enable nil))

(use-package lsp-ui
  :config
  (setq lsp-ui-doc-enable t)
  (setq lsp-ui-doc-position 'at-point)
  (setq lsp-ui-sideline-enable t)
  (setq lsp-ui-sideline-show-diagnostics t)
  (setq lsp-ui-sideline-show-hover t)
  (setq lsp-ui-sideline-show-code-actions t))

(use-package lsp-treemacs)

(provide 'emacs-jp-lsp)

;;; emacs-jp-lsp.el ends here
