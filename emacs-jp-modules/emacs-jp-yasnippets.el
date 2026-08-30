;;; emacs-jp-yasnippets.el --- YASnippet configuration -*- lexical-binding: t; -*-

;;; Commentary:

;; YASnippet global mode with extra snippets, Corfu integration and
;; Org-mode/dedicated keymap handling.

;;; Code:

(use-package yasnippet
  :config
  ;; Cargar y activar globalmente
  (require 'yasnippet)
  (yas-global-mode 1)

  ;; Hooks limpios
  ;; yas-global-mode ya se encarga de la mayoría, pero reforzamos org
  (add-hook 'org-mode-hook #'yas-minor-mode)

  ;; Evitar conflictos con Corfu
  (with-eval-after-load 'corfu
    (add-hook 'yas-before-expand-snippet-hook (lambda () (corfu-quit))))

  ;; Integración con Org-mode
  (with-eval-after-load 'org
    (defun my/org-tab-conditional ()
      (interactive)
      (if (and (bound-and-true-p yas-minor-mode)
               (yas-expand))
          (message "Snippet expandido")
        (org-cycle))) ; Si no hay snippet, hace el TAB normal de Org

    (add-hook 'org-mode-hook
              (lambda ()
                (local-set-key (kbd "<tab>") #'my/org-tab-conditional)
                (local-set-key (kbd "TAB") #'my/org-tab-conditional))))

  ;; Navegación dentro del snippet
  (define-key yas-keymap (kbd "TAB") #'yas-next-field)
  (define-key yas-keymap (kbd "<tab>") #'yas-next-field)
  (define-key yas-keymap (kbd "S-TAB") #'yas-prev-field)
  (define-key yas-keymap (kbd "<backtab>") #'yas-prev-field)

  ;; Limpieza de errores conocidos
  (setq yas-verbosity 1) ; Evita mensajes molestos en el echo area
  )

(use-package yasnippet-snippets)

(provide 'emacs-jp-yasnippets)

;;; emacs-jp-yasnippets.el ends here
