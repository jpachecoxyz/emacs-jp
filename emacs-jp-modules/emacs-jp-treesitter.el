;;; emacs-jp-treesitter.el --- Tree-sitter configuration -*- lexical-binding: t; -*-

;;; Commentary:

;; Install the tree-sitter grammar for relevant modes automatically.

;;; Code:

(use-package treesit-auto
  :config
  (setq treesit-auto-install t))

(provide 'emacs-jp-treesitter)

;;; emacs-jp-treesitter.el ends here
