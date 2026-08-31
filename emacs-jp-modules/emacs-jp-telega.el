;;; emacs-jp-telega.el --- Telega (Telegram) configuration -*- lexical-binding: t; -*-

;;; Commentary:

;; Telega client for Telegram.

;;; Code:

;; Telega is a heavy client that is only needed on demand: everything
;; here is deferred until `telega' is first invoked (there is no point
;; dragging all of telega + its dozens of features into startup).
(use-package telega
  :defer t
  :config
  (setq telega-chat-input-markups '("org" "markdown2" nil))

  (setq telega-completing-read-function #'completing-read)

  (define-key telega-chat-mode-map (kbd "S-<return>") #'newline)

  (with-eval-after-load 'telega
    (define-key telega-msg-button-map (kbd "l") nil))

  (add-hook 'telega-chat-mode-hook
            (lambda ()
              (setq-local show-trailing-whitespace nil))))

(defun my/start-telega ()
  "Start `telega' inside a new perspective and activate 'telega-mode-line-mode'"
  (interactive)
  (require 'telega)
  (if (fboundp 'persp-switch)
      (persp-switch "*telega*")
    (switch-to-buffer "*telega*"))
  (telega)
  (telega-mode-line-mode))

(provide 'emacs-jp-telega)

;;; emacs-jp-telega.el ends here
